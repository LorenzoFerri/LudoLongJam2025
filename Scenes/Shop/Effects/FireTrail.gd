extends Effect

class_name FireTrail

var time: float = 5.0
var damage: float = 2.0

static func build_random() -> Effect:
	var effect := FireTrail.new()
	effect.time = randi_range(2, 10)
	effect.damage = randi_range(1, 4)
	effect.name = "Fire Trail"
	effect.price = randi_range(100, 400)
	return effect

func build_description() -> String:
	return "Moving leaves a trail of fire that lasts [color={2}]{0}[/color] seconds and deals [color={3}]{1}[/color] damage per second.".format([
		time,
		damage,
		UpgradeUtils.get_color(time),
		UpgradeUtils.get_color(damage),
	])

func serialize() -> Dictionary:
	var data := super.serialize()
	data.time = time
	data.damage = damage
	return data

static func deserialize(data: Dictionary) -> Effect:
	var effect := FireTrail.new()
	effect.name = data.get("name", "")
	effect.price = data.get("price", 0.0)
	effect.time = data.get("time", 0.0)
	effect.damage = data.get("damage", 0.0)
	return effect
