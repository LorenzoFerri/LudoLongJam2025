extends Effect

class_name ArmorModifier


var flatValue: float = 0.0
var percentageValue: float = 0.0

static func build_random() -> Effect:
	var effect := ArmorModifier.new()
	effect.flatValue = randi_range(-4, 10)
	effect.percentageValue = randi_range(-5, 20)
	effect.name = "Improved Fuel Tank"
	effect.price = randi_range(100, 400)
	return effect

func build_description() -> String:
	var result := ""
	if flatValue > 0:
		result += "Reduce fuel lost on hit by [color={1}]{0}[/color] liters.\n".format([flatValue, UpgradeUtils.get_color(flatValue)])
	elif flatValue < 0:
		result += "Increase fuel lost on hit by [color={1}]{0}[/color] liters.\n".format([flatValue, UpgradeUtils.get_color(flatValue)])

	if percentageValue > 0:
		result += "Reduce fuel lost on hit by [color={1}]{0}[/color]%.".format([percentageValue, UpgradeUtils.get_color(percentageValue)])
	elif percentageValue < 0:
		result += "Increase fuel lost on hit [color={1}]{0}[/color]%.".format([percentageValue, UpgradeUtils.get_color(percentageValue)])

	return result

func serialize() -> Dictionary:
	var data := super.serialize()
	data.flatValue = flatValue
	data.percentageValue = percentageValue
	return data

static func deserialize(data: Dictionary) -> Effect:
	var effect := ArmorModifier.new()
	effect.name = data.get("name", "")
	effect.price = data.get("price", 0.0)
	effect.flatValue = data.get("flatValue", 0.0)
	effect.percentageValue = data.get("percentageValue", 0.0)
	return effect
