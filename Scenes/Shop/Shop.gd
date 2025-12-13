extends Control

class_name ShopUI

signal upgrade_bought(upgrade: Upgrade)

var upgrade_card_scene = preload("res://Scenes/Shop/UpgradeCard.tscn")

@onready var card_container: HBoxContainer = %CardContainer

@onready var shop_sound: AudioStreamPlayer = $ShopSound

@export var card_number := 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	
	build_remote_ui.rpc(upgrade_dicts)
	card_container.get_child(0).call_deferred("grab_focus")
	
@rpc("authority", "call_remote")
func build_remote_ui(upgrade_dicts: Array):
	for upgrade_dict in upgrade_dicts:
		var node: UpgradeCard = upgrade_card_scene.instantiate()
		node.upgrade = Upgrade.deserialize(upgrade_dict)
		card_container.add_child(node)

@rpc("any_peer", "call_local")
func buy_upgrade(upgrade_dict: Dictionary):
	var upgrade = Upgrade.deserialize(upgrade_dict)
	if multiplayer.is_server():
		PlayerState.money -= upgrade.get_price()
	PlayerState.upgrade_list.push_back(upgrade)
	upgrade_bought.emit(upgrade)
	shop_sound.play()

func show_shop():
	refresh()
	visible = true
	Engine.time_scale = 0.1

func _on_refresh_button_pressed() -> void:
	refresh()

func refresh():
	for child in card_container.get_children():
		child.queue_free()
	
	build_ui()

func _on_button_pressed() -> void:
	visible = false
	Engine.time_scale = 1
