extends Button

signal buy(upgrade: Upgrade)

@export var upgrade: Upgrade

@onready var description: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	build_ui()

func _on_pressed() -> void:
	buy.emit(upgrade)

func build_ui():
	var descText = ""
	
	if upgrade.condition != null:
		descText += "[b][font_size=32]" + upgrade.condition.name + "[/font_size][/b]\n"
		descText += upgrade.condition.build_description() + "\n"
		
	descText += "[ul]"
	for effect in upgrade.effects:
		descText += "[b][font_size=32]" + effect.name + "[/font_size][/b]\n"
		descText += effect.build_description() + "\n"
	

	descText += "[/ul]"
	
	description.text = descText
