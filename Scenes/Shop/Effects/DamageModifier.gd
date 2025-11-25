extends "res://Scenes/Shop/Effects/Effect.gd"

class_name DamageModifier

const UpgradeUtilsClass = preload("res://Scenes/Shop/UpgradeUtils.gd")

var flatValue: float = 0.0
var percentageValue: float = 0.0

static func build_random() -> Effect:
	var effect := DamageModifier.new()
	effect.flatValue = randi_range(2, 10)
	effect.percentageValue = randi_range(5, 20)
	effect.name = "Damage Increase"
	effect.price = randi_range(100, 400)
	return effect

func build_description() -> String:
	var result := ""
	if flatValue > 0:
		result += "Increase damage by [color={1}]{0}[/color] per hit.\n".format([flatValue, UpgradeUtilsClass.get_color(flatValue)])
	elif flatValue < 0:
		result += "Decrease damage by [color={1}]{0}[/color] per hit.\n".format([flatValue, UpgradeUtilsClass.get_color(flatValue)])

	if percentageValue > 0:
		result += "Increase damage by [color={1}]{0}[/color]% per hit.".format([percentageValue, UpgradeUtilsClass.get_color(percentageValue)])
	elif percentageValue < 0:
		result += "Decrease damage by [color={1}]{0}[/color]% per hit.".format([percentageValue, UpgradeUtilsClass.get_color(percentageValue)])

	return result

func serialize() -> Dictionary:
	var data := super.serialize()
	data.flatValue = flatValue
	data.percentageValue = percentageValue
	return data

static func deserialize(data: Dictionary) -> Effect:
	var effect := DamageModifier.new()
	effect.name = data.get("name", "")
	effect.price = data.get("price", 0.0)
	effect.flatValue = data.get("flatValue", 0.0)
	effect.percentageValue = data.get("percentageValue", 0.0)
	return effect
