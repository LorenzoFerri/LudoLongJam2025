extends Resource

class_name Condition

var name: String
var price: float = 1000.0

static func build_condition() -> Condition:
	return null

func build_description() -> String:
	return ""

func serialize() -> Dictionary:
	var data: Dictionary = {}
	var script: Script = get_script()
	if script and script.resource_path != "":
		data.type = script.resource_path
	else:
		data.type = get_class()
	data.class_name = get_class()
	data.name = name
	data.price = price
	return data

static func deserialize(data: Dictionary) -> Condition:
	var condition := Condition.new()
	condition.name = data.get("name", "")
	condition.price = data.get("price", 0.0)
	return condition
