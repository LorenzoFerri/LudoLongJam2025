extends "res://Scenes/Shop/Effects/Effect.gd"

class_name ExplodingBullets

const UpgradeUtils = preload("res://Scenes/Shop/UpgradeUtils.gd")

var radius: float = 2.0
var damage: float = 2.0

static func build_random() -> Effect:
	var effect := ExplodingBullets.new()
	effect.radius = randi_range(2, 10)
	effect.damage = randi_range(1, 6)
	effect.name = "Exploding Bullets"
	effect.price = randi_range(100, 400)
	return effect

func build_description() -> String:
	return "Create an explosion on hit that deals [color={3}]{1}[/color] damage over an area of [color={2}]{0}[/color] meters.".format([
		radius,
		damage,
		UpgradeUtils.get_color(radius),
		UpgradeUtils.get_color(damage),
	])

func serialize() -> Dictionary:
	var data := super.serialize()
	data.radius = radius
	data.damage = damage
	return data

static func deserialize(data: Dictionary) -> Effect:
	var effect := ExplodingBullets.new()
	effect.name = data.get("name", "")
	effect.price = data.get("price", 0.0)
	effect.radius = data.get("radius", 0.0)
	effect.damage = data.get("damage", 0.0)
	return effect
