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

var sleep_mode := false;
var sleep_mode_information_delivered := false

var old_global_transform = Transform3D();
var old_quaternion = Quaternion();
var old_scale = Vector3();

var transform_state_buffer = [] # [old_State (0), future_state (1)] - buffer for interpolation, stores old and new data
var interpolation_offset_ms := 100 # The current time in milliseconds, which the game is interpolated (depends on the speed of receiving data from the server and on the server load) this is necessary for smooth movement, and this value is changed by the algorithm depending on the speed of receiving data from the server and on its load

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
			
		var interpolation_factor := float(render_time - transform_state_buffer[0].snap_time_ms) / float(transform_state_buffer[1].snap_time_ms - transform_state_buffer[0].snap_time_ms)
		
		if transform_state_buffer[1].sleep_mode == true:
			if sync_global_transform:
				track_this_object.global_transform = transform_state_buffer[1].global_transform
			if sync_quaternion:
				track_this_object.quaternion = transform_state_buffer[1].quaternion
			if sync_scale:
				track_this_object.scale = transform_state_buffer[1].scale
			transform_state_buffer[1].snap_time_ms = render_time
			return
		
		recalculate_interpolation_offset_ms(interpolation_factor)
		
		if sync_global_transform:
			# track_this_object.global_transform = lerp(transform_state_buffer[0].global_transform, transform_state_buffer[1].global_transform, interpolation_factor)
			track_this_object.global_transform = transform_state_buffer[0].global_transform.interpolate_with(transform_state_buffer[1].global_transform, interpolation_factor)
		if sync_quaternion:
			track_this_object.quaternion = lerp(transform_state_buffer[0].quaternion, transform_state_buffer[1].quaternion, interpolation_factor)
		if sync_scale:
			track_this_object.scale = lerp(transform_state_buffer[0].scale, transform_state_buffer[1].scale, interpolation_factor)
		
func recalculate_interpolation_offset_ms(interpolation_factor: float):
	if interpolation_factor > 1 && interpolation_offset_ms < interpolation_offset_max:
		interpolation_offset_ms += 1
	else:
		if transform_state_buffer.size() > 2 && interpolation_offset_ms > interpolation_offset_min:
			interpolation_offset_ms -= 1

func get_current_unix_time_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000)

func _physics_process(_delta: float) -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		sync_transform()

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
	
	_sync_transform.rpc(
		track_this_object.global_transform if sync_global_transform else Transform3D(),
		track_this_object.quaternion if sync_quaternion else Quaternion(),
		track_this_object.scale if sync_scale else Vector3(),
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
	if sync_global_transform:
		track_this_object.global_transform = new_global_transform
	if sync_quaternion:
		track_this_object.quaternion = new_quaternion
	if sync_scale:
		track_this_object.scale = new_scale
	
@rpc("any_peer", "call_remote", "reliable")
func _request_transform() -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		_respone_transform.rpc(
			track_this_object.global_transform if sync_global_transform else Transform3D(),
			track_this_object.quaternion if sync_quaternion else Quaternion(),
			track_this_object.scale if sync_scale else Vector3()
		)
