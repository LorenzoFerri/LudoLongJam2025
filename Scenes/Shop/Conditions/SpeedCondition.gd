extends "res://Scenes/Shop/Conditions/Condition.gd"

class_name SpeedCondition

const UpgradeUtilsClass = preload("res://Scenes/Shop/UpgradeUtils.gd")

var greaterThan: bool
var value: float

func check(speed: float) -> bool:
	if greaterThan:
		return speed >= value
	return speed <= value

static func build_condition() -> Condition:
	var result := SpeedCondition.new()
	result.value = randf_range(10, 25)
	result.greaterThan = randi_range(0, 2) == 1
	result.name = "Speed Limit"
	result.price = randi_range(100, 400)
	return result

func build_description() -> String:
	var color: String = UpgradeUtilsClass.get_color(value)
	if greaterThan:
		return "When your speed is greater than [color={1}]{0}[/color]:".format([value, color])
	return "When your speed is less than [color={1}]{0}[/color]:".format([value, color])

func serialize() -> Dictionary:
	var data := super.serialize()
	data.greaterThan = greaterThan
	data.value = value
	return data

static func deserialize(data: Dictionary) -> Condition:
	var condition := SpeedCondition.new()
	condition.name = data.get("name", "")
	condition.price = data.get("price", 0.0)
	condition.greaterThan = data.get("greaterThan", false)
	condition.value = data.get("value", 0.0)
	return condition
