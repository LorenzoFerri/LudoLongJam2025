extends Control

class_name ShopUI

signal upgrade_bought(upgrade: Upgrade)

var upgrade_card_scene = preload("res://Scenes/Shop/UpgradeCard.tscn")

@onready var card_container: HBoxContainer = %CardContainer


@export var card_number := 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	build_ui()

func build_ui():
	if not multiplayer.is_server():
		return
	for i in range(card_number):
		var node: UpgradeCard = upgrade_card_scene.instantiate()
		
		node.upgrade = Upgrade.get_random_upgrade()
		
		if i > 0:
			var previous_card = card_container.get_child(i - 1)
			node.focus_previous = previous_card.get_path()
		
		node.buy.connect(upgrade_bought.emit)
			
		card_container.add_child(node, true)
	
	card_container.get_child(0).grab_focus()

func show_shop():
	refresh()
	visible = true
	Engine.time_scale = 0

func _on_refresh_button_pressed() -> void:
	refresh()

func refresh():
	for child in card_container.get_children():
		child.queue_free()
	
	build_ui()

func _on_button_pressed() -> void:
	visible = false
	Engine.time_scale = 1
