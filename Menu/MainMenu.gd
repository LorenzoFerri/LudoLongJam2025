extends Control

@onready var join_window: Window = $JoinWindow
@onready var ipline_edit: LineEdit = %IPLineEdit
@onready var lobby_scene: PackedScene = preload("res://Menu/Lobby.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_join_button_pressed() -> void:
	join_window.popup_centered()

func _on_host_button_pressed() -> void:
	if MultiplayerManager.host_game():
		get_tree().change_scene_to_packed.call_deferred(lobby_scene)
	else:
		OS.alert("Failed to host game.", "Error")

func _on_cancel_pressed() -> void:
	join_window.hide()
	ipline_edit.clear()

func _on_join_window_close_requested() -> void:
	_on_cancel_pressed()

func _on_confirm_pressed() -> void:
	if MultiplayerManager.join_game(ipline_edit.text):
		get_tree().change_scene_to_packed.call_deferred(lobby_scene)
	else:
		OS.alert("Failed to join game.", "Error")
