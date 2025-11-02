extends MarginContainer

@onready var driver_container: VBoxContainer = %DriverContainer
@onready var shooter_container: VBoxContainer = %ShooterContainer
@onready var start_button: Button = %StartButton

func _ready() -> void:
	build_containers()
	MultiplayerManager.players_changed.connect(build_containers)
	MultiplayerManager.multiplayer.server_disconnected.connect(server_disconnected)

func build_containers() -> void:
	for driver in driver_container.get_children():
		driver_container.remove_child(driver)
		driver.queue_free()
	for shooter in shooter_container.get_children():
		shooter_container.remove_child(shooter)
		shooter.queue_free()
	for player_id in MultiplayerManager.players.keys():
		var role = MultiplayerManager.players[player_id]
		var label = create_player_label(player_id)
		if role == MultiplayerManager.Role.DRIVER:
			driver_container.add_child(label)
		elif role == MultiplayerManager.Role.SHOOTER:
			shooter_container.add_child(label)
	if MultiplayerManager.multiplayer.is_server():
		start_button.disabled = driver_container.get_child_count() != 1 || shooter_container.get_child_count() != 1
	else:
		start_button.disabled = true

func server_disconnected() -> void:
	OS.alert("Disconnected from server.", "Connection Lost")
	_on_back_button_pressed()

func _on_back_button_pressed() -> void:
	MultiplayerManager.close_game()
	get_tree().change_scene_to_file("res://Menu/MainMenu.tscn")

func _on_shooting_button_pressed() -> void:
	MultiplayerManager.set_player_role.rpc(MultiplayerManager.multiplayer.get_unique_id(), MultiplayerManager.Role.SHOOTER)

func _on_driving_button_pressed() -> void:
	MultiplayerManager.set_player_role.rpc(MultiplayerManager.multiplayer.get_unique_id(), MultiplayerManager.Role.DRIVER)

func create_player_label(player_id: int) -> Label:
	var label = Label.new()
	label.text = "Player 1" if player_id == 1 else "Player 2"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.INDIAN_RED if player_id == 1 else Color.ROYAL_BLUE)
	return label


func _on_start_button_pressed() -> void:
	MultiplayerManager.change_scene.rpc("res://World/World.tscn")
	
