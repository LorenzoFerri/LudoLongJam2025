extends Resource

class_name Upgrade

var effects: Array[Effect] = []
var weapon: Weapon = null
var condition: Condition = null


class Condition:
	var name: String
	var price: float = 1000.0

	static func build_condition() -> Condition:
		return null


class SpeedCondition extends Condition:
	var greaterThan: bool
	var value: float
	
	func check(speed: float) -> bool:
		if greaterThan:
			return speed >= value
		else:
			return speed <= value
	
	static func build_condition() -> Condition:
		var result = SpeedCondition.new()
		
		result.value = randf_range(50, 200)
		result.greaterThan = randi_range(0, 2) == 1
		result.name = "Speed Limit"
		
		return result
	
	func build_description() -> String:
		var result = ""
		
		if greaterThan:
			result = "When your speed is greater than [color={1}]{0}[/color]:".format([value, Upgrade.get_color(value)])
		else:
			result = "When your speed is less than [color={1}]{0}[/color]:".format([value, Upgrade.get_color(value)])
		
		return result

class EveryNShotCondition extends Condition:
	var frequency: int
	
	func check(total_shots: int):
		return total_shots % frequency == 0
	
	static func build_condition() -> Condition:
		var result = EveryNShotCondition.new()
		
		result.frequency = randf_range(2, 5)
		result.name = "Hit counter"
		
		return result
	
	func build_description() -> String:
		return "Every [color={1}]{0}[/color] shots:".format([frequency, Upgrade.get_color(frequency)])


class Effect:
	var name: String
	var price: float
	
	func build_description() -> String:
		return ""
	
	static func build_random() -> Effect:
		assert(false)
		return null

class DamageModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	static func build_random() -> Effect:
		var effect = DamageModifier.new()
		effect.flatValue = randi_range(2, 10)
		effect.percentageValue = randi_range(5, 20)
		effect.name = "Damage Increase"
		return effect
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase damage by [color={1}]{0}[/color] per hit.\n".format([flatValue, Upgrade.get_color(flatValue)])
		elif flatValue < 0:
			result += "Decrease damage by [color={1}]{0}[/color] per hit.\n".format([flatValue, Upgrade.get_color(flatValue)])
		
		if percentageValue > 0:
			result += "Increase damage by [color={1}]{0}[/color]% per hit.".format([percentageValue, Upgrade.get_color(percentageValue)])
		elif percentageValue < 0:
			result += "Decrease damage by [color={1}]{0}[/color]% per hit.".format([percentageValue, Upgrade.get_color(percentageValue)])
		
		return result

class SpeedModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	static func build_random() -> Effect:
		var effect = SpeedModifier.new()
		effect.flatValue = randi_range(-4, 10)
		effect.percentageValue = randi_range(-5, 20)
		effect.name = "Speed Increase"
		return effect
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase maximum speed by [color={1}]{0}[/color].\n".format([flatValue, Upgrade.get_color(flatValue)])
		elif flatValue < 0:
			result += "Decrease maximum speed by [color={1}]{0}[/color].\n".format([flatValue, Upgrade.get_color(flatValue)])
		
		if percentageValue > 0:
			result += "Increase maximum speed by [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		elif percentageValue < 0:
			result += "Decrease maximum speed by [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		
		return result

class FuelModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	static func build_random() -> Effect:
		var effect = FuelModifier.new()
		effect.flatValue = randi_range(-4, 10)
		effect.percentageValue = randi_range(-5, 20)
		effect.name = "Fuel Increase"
		return effect
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase maximum fuel by [color={1}]{0}[/color] liters.\n".format([flatValue, Upgrade.get_color(flatValue)])
		elif flatValue < 0:
			result += "Decrease maximum fuel by [color={1}]{0}[/color] liters.\n".format([flatValue, Upgrade.get_color(flatValue)])
		
		if percentageValue > 0:
			result += "Increase maximum fuel by [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		elif percentageValue < 0:
			result += "Decrease maximum fuel by [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		
		return result

class ArmorModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	static func build_random() -> Effect:
		var effect = ArmorModifier.new()
		effect.flatValue = randi_range(-4, 10)
		effect.percentageValue = randi_range(-5, 20)
		effect.name = "Improved Fuel Tank"
		return effect
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Reduce fuel lost on hit by [color={1}]{0}[/color] liters.\n".format([flatValue, Upgrade.get_color(flatValue)])
		elif flatValue < 0:
			result += "Increase fuel lost on hit by [color={1}]{0}[/color] liters.\n".format([flatValue, Upgrade.get_color(flatValue)])
		
		if percentageValue > 0:
			result += "Reduce fuel lost on hit by [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		elif percentageValue < 0:
			result += "Increase fuel lost on hit [color={1}]{0}[/color]%.".format([percentageValue, Upgrade.get_color(percentageValue)])
		
		return result

class ExplodingBullets extends Effect:
	var radius: float = 2
	var damage: float = 2
	
	static func build_random() -> Effect:
		var effect = ExplodingBullets.new()
		effect.radius = randi_range(2, 10)
		effect.damage = randi_range(1, 6)
		effect.name = "Exploding Bullets"
		return effect
	
	func build_description() -> String:
		return "Create an explosion on hit that deals [color={3}]{1}[/color] damage over an area of [color={2}]{0}[/color] meters.".format([radius, damage, Upgrade.get_color(radius), Upgrade.get_color(damage)])

class FireTrail extends Effect:
	var time: float = 5
	var damage: float = 2
	
	static func build_random() -> Effect:
		var effect = FireTrail.new()
		effect.time = randi_range(2, 10)
		effect.damage = randi_range(1, 4)
		effect.name = "Fire Trail"
		return effect
	
	func build_description() -> String:
		return "Moving leaves a trail of fire that lasts [color={2}]{0}[/color] seconds and deals [color={3}]{1}[/color] damage per second.".format([time, damage, Upgrade.get_color(time), Upgrade.get_color(damage)])


static func get_random_upgrade() -> Upgrade:
	var result: Upgrade = Upgrade.new()
	
	var n_effects = [1, 1, 1, 1, 2, 2, 3].pick_random()
	var n_conditions = [0, 0, 0, 1].pick_random()
	
	for i in range(n_effects):
		result.effects.push_back(get_random_effect())
	
	for i in range(n_conditions):
		result.condition = get_random_condition()
	
	return result


static func get_random_condition() -> Condition:
	var i = randi_range(0, 1)
	
	match i:
		0: return SpeedCondition.build_condition()
		1: return EveryNShotCondition.build_condition()
		
	return null


static func get_random_effect() -> Effect:
	var i = randi_range(0, 5)
	
	match i:
		0: return DamageModifier.build_random()
		1: return SpeedModifier.build_random()
		2: return FuelModifier.build_random()
		3: return ArmorModifier.build_random()
		4: return ExplodingBullets.build_random()
		5: return FireTrail.build_random()
	
	return null

static func get_color(value):
	if value < 0: 
		return "tomato"
	
	return "lightgreen"
