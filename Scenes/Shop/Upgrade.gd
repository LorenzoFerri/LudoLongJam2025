extends Resource

class_name Upgrade

var effects: Array[Effect] = []
var weapon: Weapon = null
var condition: Condition = null


class Condition:
	var name: String
	var price: float


class SpeedCondition extends Condition:
	var greaterThan: bool
	var value: float
	
	func check(speed: float) -> bool:
		if greaterThan:
			return speed >= value
		else:
			return speed <= value
	
	func build_description() -> String:
		var result = ""
		
		if greaterThan:
			result = "When your speed is greater than %d:".format(value)
		else:
			result = "When your speed is less than %d:".format(value)
		
		return result

class EveryNShotCondition extends Condition:
	var frequency: int
	
	func check(total_shots: int):
		return total_shots % frequency == 0
	
	func build_description() -> String:
		return "Every %d shots:".format(frequency)


class Effect:
	var name: String
	var price: float
	
	func build_description() -> String:
		return ""

class DamageModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase damage by %d per hit.".format(flatValue)
		elif flatValue < 0:
			result += "Decrease damage by %d per hit.".format(flatValue)
		
		if percentageValue > 0:
			result += "Increase damage by %d% per hit.".format(percentageValue)
		elif percentageValue < 0:
			result += "Decrease damage by %d% per hit.".format(percentageValue)
		
		return result

class SpeedModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase maximum speed by %d.".format(flatValue)
		elif flatValue < 0:
			result += "Decrease maximum speed by %d.".format(flatValue)
		
		if percentageValue > 0:
			result += "Increase maximum speed by %d%.".format(percentageValue)
		elif percentageValue < 0:
			result += "Decrease maximum speed by %d%.".format(percentageValue)
		
		return result

class FuelModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Increase maximum fuel by %d liters.".format(flatValue)
		elif flatValue < 0:
			result += "Decrease maximum fuel by %d liters.".format(flatValue)
		
		if percentageValue > 0:
			result += "Increase maximum fuel by %d%.".format(percentageValue)
		elif percentageValue < 0:
			result += "Decrease maximum fuel by %d%.".format(percentageValue)
		
		return result

class ArmorModifier extends Effect:
	var flatValue: float = 0
	var percentageValue: float = 0
	
	func build_description() -> String:
		var result = ""
		if flatValue > 0:
			result += "Reduce fuel lost on hit by %d liters.".format(flatValue)
		elif flatValue < 0:
			result += "Increase fuel lost on hit by %d liters.".format(flatValue)
		
		if percentageValue > 0:
			result += "Reduce fuel lost on hit by %d%.".format(percentageValue)
		elif percentageValue < 0:
			result += "Increase fuel lost on hit %d%.".format(percentageValue)
		
		return result

class ExplodingBullets extends Effect:
	var radius: float = 2
	var damage: float = 2
	
	func build_description() -> String:
		return "Create an explosion on hit that deals %d damage over an area of %d meters.".format([radius, damage])

class FireTrail extends Effect:
	var time: float = 5
	var damage: float = 2
	
	func build_description() -> String:
		return "Moving leaves a trail of fire that lasts %d seconds and deals %d damage per second.".format([time, damage])
