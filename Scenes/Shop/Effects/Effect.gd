extends Resource

class_name Effect

var name: String
var price: float

func build_description() -> String:
	return ""

static func build_random() -> Effect:
	push_error("Effect.build_random must be implemented in subclasses.")
	return null

func serialize() -> Dictionary:
	var data: Dictionary = {}
	data.type = get_class()
	data.name = name
	data.price = price
	return data

static func deserialize(data: Dictionary) -> Effect:
	var effect := Effect.new()
	effect.name = data.get("name", "")
	effect.price = data.get("price", 0.0)
	return effect
