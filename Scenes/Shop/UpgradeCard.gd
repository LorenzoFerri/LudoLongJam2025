extends Button

class_name UpgradeCard

signal buy(upgrade: Upgrade)

@export var upgrade: Upgrade

@onready var description: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var price_label: RichTextLabel = $MarginContainer/VBoxContainer/PriceLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	build_ui()

func _on_pressed() -> void:
	if PlayerState.money < upgrade.get_price():
		return
	
	buy.emit(upgrade)
	disabled = true

func build_ui():
	if PlayerState.money < upgrade.get_price():
		disabled = true
	
	price_label.text = "Price: [color=gold]{0}[/color]".format([upgrade.get_price()])
	
	var descText = "[font_size=24]"
	
	if upgrade.condition != null:
		descText += "[b][font_size=42]" + upgrade.condition.name + "[/font_size][/b]\n"
		descText += upgrade.condition.build_description() + "\n\n"
		
	descText += "[ul]"
	for effect in upgrade.effects:
		descText += "[b][font_size=28]" + effect.name + "[/font_size][/b]\n[ul]"
		descText += effect.build_description() + "\n[/ul]"
	

	descText += "[/ul][/font_size]"
	
	description.text = descText
