extends "res://Scenes/Shop/Conditions/Condition.gd"

class_name EveryNShotCondition

const UpgradeUtils = preload("res://Scenes/Shop/UpgradeUtils.gd")

var frequency: int

func check(total_shots: int) -> bool:
	return frequency != 0 and total_shots % frequency == 0

static func build_condition() -> Condition:
	var result := EveryNShotCondition.new()
	result.frequency = randi_range(2, 5)
	result.name = "Hit counter"
	result.price = randi_range(100, 400)
	return result

func build_description() -> String:
	var color: String = UpgradeUtils.get_color(frequency)
	return "Every [color={1}]{0}[/color] shots:".format([frequency, color])

func serialize() -> Dictionary:
	var data := super.serialize()
	data.frequency = frequency
	return data

static func deserialize(data: Dictionary) -> Condition:
	var condition := EveryNShotCondition.new()
	condition.name = data.get("name", "")
	condition.price = data.get("price", 0.0)
	condition.frequency = data.get("frequency", 0)
	return condition
