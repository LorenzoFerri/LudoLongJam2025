# The purpose of this script is to synchronize global_transform, quaternion and scale
# using frame interpolation (so that the object does not twitch at low server TPS)

extends Node

@export_group("What to sync? (main node)")
## The node whose parameters will be synchronized
@export var track_this_object: Node3D # Сделать проверку на то существует ли этот обьект

@export_group("What to sync?")
@export var sync_global_transform := true
@export var sync_quaternion := true
@export var sync_scale := true

@export_group("Min-Max acceptable delay in the client")
## Minimum threshold for interpolation_offset_ms
@export_range(1, 10)  var interpolation_offset_min := 1
## Maximum threshold for interpolation_offset_ms (500 - quite enough even for a very lagging server)
@export_range(20, 500) var interpolation_offset_max := 500

@export_group("Sync Settings")
## Number of syncs per second (higher = smoother but more bandwidth)
@export_range(10, 60) var sync_rate_hz := 30

var sleep_mode := false;
var sleep_mode_information_delivered := false
var last_sync_time := 0.0  # Tempo dell'ultima sincronizzazione

var old_global_transform = Transform3D();
var old_quaternion = Quaternion();
var old_scale = Vector3();

var transform_state_buffer = [] # [old_State (0), future_state (1)] - buffer for interpolation, stores old and new data
var interpolation_offset_ms := 100.0 # The current time in milliseconds, which the game is interpolated (depends on the speed of receiving data from the server and on the server load) this is necessary for smooth movement, and this value is changed by the algorithm depending on the speed of receiving data from the server and on its load
var buffer_size_samples = [] # Track buffer size over time for adaptive interpolation

func _ready() -> void:
	if track_this_object == null:
		assert(false, "Add a node for 'track_this_object' in the inspector")
	if !multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		_request_transform.rpc()

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		return
	
	var render_time := get_current_unix_time_ms() - interpolation_offset_ms

	if transform_state_buffer.size() > 1:
		while transform_state_buffer.size() > 2 and render_time > transform_state_buffer[1].snap_time_ms:
			transform_state_buffer.remove_at(0)
			
		# Prevenire divisione per zero
		var time_diff: int = transform_state_buffer[1].snap_time_ms - transform_state_buffer[0].snap_time_ms
		if time_diff <= 0:
			return
			
		var interpolation_factor := float(render_time - transform_state_buffer[0].snap_time_ms) / float(time_diff)
		
		# Clamp l'interpolation factor per evitare estrapolazioni eccessive
		interpolation_factor = clamp(interpolation_factor, 0.0, 1.2)
		
		if transform_state_buffer[1].sleep_mode == true:
			if sync_global_transform and is_transform_valid(transform_state_buffer[1].global_transform):
				track_this_object.global_transform = transform_state_buffer[1].global_transform
			if sync_quaternion and is_quaternion_valid(transform_state_buffer[1].quaternion):
				track_this_object.quaternion = transform_state_buffer[1].quaternion
			if sync_scale and is_vector3_valid(transform_state_buffer[1].scale):
				track_this_object.scale = transform_state_buffer[1].scale
			transform_state_buffer[1].snap_time_ms = render_time
			return
		
		recalculate_interpolation_offset_ms(interpolation_factor)
		
		# Interpolare solo se i valori sono validi
		if sync_global_transform:
			var interpolated_transform = transform_state_buffer[0].global_transform.interpolate_with(transform_state_buffer[1].global_transform, interpolation_factor)
			if is_transform_valid(interpolated_transform):
				track_this_object.global_transform = interpolated_transform
		if sync_quaternion:
			var interpolated_quaternion = transform_state_buffer[0].quaternion.slerp(transform_state_buffer[1].quaternion, interpolation_factor)
			if is_quaternion_valid(interpolated_quaternion):
				track_this_object.quaternion = interpolated_quaternion
		if sync_scale:
			var interpolated_scale = lerp(transform_state_buffer[0].scale, transform_state_buffer[1].scale, interpolation_factor)
			if is_vector3_valid(interpolated_scale):
				track_this_object.scale = interpolated_scale
	elif transform_state_buffer.size() == 1:
		# Se abbiamo solo un campione, usalo direttamente
		if sync_global_transform and is_transform_valid(transform_state_buffer[0].global_transform):
			track_this_object.global_transform = transform_state_buffer[0].global_transform
		if sync_quaternion and is_quaternion_valid(transform_state_buffer[0].quaternion):
			track_this_object.quaternion = transform_state_buffer[0].quaternion
		if sync_scale and is_vector3_valid(transform_state_buffer[0].scale):
			track_this_object.scale = transform_state_buffer[0].scale
		
func recalculate_interpolation_offset_ms(interpolation_factor: float):
	# Algoritmo più fluido e meno aggressivo per l'interpolazione
	buffer_size_samples.append(transform_state_buffer.size())
	if buffer_size_samples.size() > 30:  # Mantieni solo gli ultimi 30 campioni (circa 0.5 secondi a 60fps)
		buffer_size_samples.pop_front()
	
	# Se stiamo interpolando troppo avanti (factor > 1), aumenta l'offset
	if interpolation_factor > 1.0:
		if interpolation_offset_ms < interpolation_offset_max:
			# Aumenta più velocemente se siamo molto avanti
			var increment = 2 if interpolation_factor > 1.5 else 1
			interpolation_offset_ms += increment
	# Se abbiamo un buon buffer e siamo indietro, diminuisci l'offset
	elif interpolation_factor < 0.9 and transform_state_buffer.size() > 3:
		if interpolation_offset_ms > interpolation_offset_min:
			# Diminuisci lentamente per evitare jitter
			interpolation_offset_ms -= 0.5
	# Mantieni un buffer minimo
	elif transform_state_buffer.size() < 2 and interpolation_offset_ms < interpolation_offset_max:
		interpolation_offset_ms += 1

func get_current_unix_time_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000)

func _physics_process(_delta: float) -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		# Throttle basato sul tempo invece che sul frame rate
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_sync_time >= (1.0 / sync_rate_hz):
			sync_transform()
			last_sync_time = current_time

func sync_transform() -> void:
	var at_least_one_has_been_changed := false
	
	if sync_global_transform && track_this_object.global_transform != old_global_transform:
		at_least_one_has_been_changed = true
		
	if sync_quaternion && track_this_object.quaternion != old_quaternion:
		at_least_one_has_been_changed = true
		
	if sync_scale && track_this_object.scale != old_scale:
		at_least_one_has_been_changed = true
	
	# If none of the synchronized data values ​​have been changed, we enter sleep mode
	sleep_mode = not at_least_one_has_been_changed;
	
	if sleep_mode && sleep_mode_information_delivered:
		return
	
	sleep_mode_information_delivered = false
	
	# Validare i valori prima di inviarli
	var transform_to_send = track_this_object.global_transform if sync_global_transform else Transform3D()
	var quaternion_to_send = track_this_object.quaternion if sync_quaternion else Quaternion()
	var scale_to_send = track_this_object.scale if sync_scale else Vector3()
	
	# Non inviare se i valori non sono validi
	if (sync_global_transform and not is_transform_valid(transform_to_send)) or \
	   (sync_quaternion and not is_quaternion_valid(quaternion_to_send)) or \
	   (sync_scale and not is_vector3_valid(scale_to_send)):
		print("Warning: Attempting to sync invalid transform values")
		return
	
	_sync_transform.rpc(
		transform_to_send,
		quaternion_to_send,
		scale_to_send,
		get_current_unix_time_ms(),
		sleep_mode
	)
	
	if sync_global_transform:
		old_global_transform = track_this_object.global_transform
		
	if sync_quaternion:
		old_quaternion = track_this_object.quaternion
		
	if sync_scale:
		old_scale = track_this_object.scale
		
	if sleep_mode:
		sleep_mode_information_delivered = true

@rpc("authority", "call_remote", "unreliable_ordered")
func _sync_transform(new_global_transform: Transform3D, new_quaternion: Quaternion, new_scale: Vector3, snap_time_ms: int, sleep_mode_ = false) -> void:
	var snap = {
		"snap_time_ms": snap_time_ms,
		"global_transform": new_global_transform,
		"quaternion": new_quaternion,
		"scale": new_scale,
		"sleep_mode": sleep_mode_
	}
	transform_state_buffer.append(snap)

@rpc("authority", "call_remote", "reliable")
func _respone_transform(new_global_transform: Transform3D, new_quaternion: Quaternion, new_scale: Vector3) -> void:
	if sync_global_transform and is_transform_valid(new_global_transform):
		track_this_object.global_transform = new_global_transform
	if sync_quaternion and is_quaternion_valid(new_quaternion):
		track_this_object.quaternion = new_quaternion
	if sync_scale and is_vector3_valid(new_scale):
		track_this_object.scale = new_scale
	
@rpc("any_peer", "call_remote", "reliable")
func _request_transform() -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		_respone_transform.rpc(
			track_this_object.global_transform if sync_global_transform else Transform3D(),
			track_this_object.quaternion if sync_quaternion else Quaternion(),
			track_this_object.scale if sync_scale else Vector3()
		)

# Funzioni di validazione per prevenire valori non finiti
func is_transform_valid(transform: Transform3D) -> bool:
	return is_vector3_valid(transform.origin) and is_vector3_valid(transform.basis.x) and is_vector3_valid(transform.basis.y) and is_vector3_valid(transform.basis.z)

func is_quaternion_valid(quat: Quaternion) -> bool:
	return is_finite(quat.x) and is_finite(quat.y) and is_finite(quat.z) and is_finite(quat.w)

func is_vector3_valid(vec: Vector3) -> bool:
	return is_finite(vec.x) and is_finite(vec.y) and is_finite(vec.z)
