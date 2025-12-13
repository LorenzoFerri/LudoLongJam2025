extends Control

class_name ShopUI

signal upgrade_bought(upgrade: Upgrade)

var upgrade_card_scene = preload("res://Scenes/Shop/UpgradeCard.tscn")

@onready var card_container: HBoxContainer = %CardContainer

@onready var shop_sound: AudioStreamPlayer = $ShopSound
@onready var refresh_button: Button = $PanelContainer/MarginContainer/VBoxContainer/RefreshButton

@export var card_number := 3

@export var refresh_base_cost := 2000
var current_refresh_cost = refresh_base_cost

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_refresh_cost = refresh_base_cost
	build_ui()

func build_ui():
	if not multiplayer.is_server():
		return
	var upgrade_dicts: Array = []
	for i in range(card_number):
		var node: UpgradeCard = upgrade_card_scene.instantiate()
		
		node.upgrade = Upgrade.get_random_upgrade()
		if i > 0:
			var previous_card = card_container.get_child(i - 1)
			node.focus_previous = previous_card.get_path()
		
		node.buy.connect(func(upgrade):
			buy_upgrade.rpc(upgrade.serialize())
		)
		upgrade_dicts.append(node.upgrade.serialize())
		card_container.add_child(node)
		
		refresh_button.text = "Refresh ({0})".format([current_refresh_cost])
		if current_refresh_cost > PlayerState.money:
			refresh_button.disabled = true
		else:
			refresh_button.disabled = false
	
	build_remote_ui.rpc(upgrade_dicts)
	card_container.get_child(0).call_deferred("grab_focus")
	
@rpc("authority", "call_remote")
func build_remote_ui(upgrade_dicts: Array):
	for upgrade_dict in upgrade_dicts:
		var node: UpgradeCard = upgrade_card_scene.instantiate()
		node.upgrade = Upgrade.deserialize(upgrade_dict)
		card_container.add_child(node)
	
	refresh_button.text = "Refresh ({0})".format([current_refresh_cost])
	if current_refresh_cost > PlayerState.money:
		refresh_button.disabled = true
	else:
		refresh_button.disabled = false
	
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

@rpc("any_peer", "call_local")
func buy_upgrade(upgrade_dict: Dictionary):
	var upgrade = Upgrade.deserialize(upgrade_dict)
	if multiplayer.is_server():
		PlayerState.money -= upgrade.get_price()
	PlayerState.upgrade_list.push_back(upgrade)
	upgrade_bought.emit(upgrade)
	shop_sound.play()

@rpc("any_peer", "call_local")
func show_shop():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if multiplayer.is_server():
		refresh.rpc(true)
	visible = true
	
	await get_tree().process_frame
	if card_container.get_child_count() > 0:
		var child = card_container.get_child(0)
		if child != null:
			child.grab_focus()
	
	Engine.time_scale = 0.1

func _on_refresh_button_pressed() -> void:
	refresh.rpc(false)

@rpc("any_peer", "call_local")
func refresh(free: bool):
	for child in card_container.get_children():
		child.queue_free()
	
	if multiplayer.is_server() and not free:
		PlayerState.money -= current_refresh_cost
	if not free:
		current_refresh_cost *= 2
	
	if multiplayer.is_server():
		build_ui()

func _on_button_pressed() -> void:
	visible = false
	Engine.time_scale = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PlayerState.fuel = PlayerState.max_fuel
