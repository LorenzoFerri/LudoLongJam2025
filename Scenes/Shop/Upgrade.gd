extends Resource

class_name Upgrade

const UpgradeUtilsClass = preload("res://Scenes/Shop/UpgradeUtils.gd")

const ConditionClass = preload("res://Scenes/Shop/Conditions/Condition.gd")
const SpeedConditionClass = preload("res://Scenes/Shop/Conditions/SpeedCondition.gd")
const EveryNShotConditionClass = preload("res://Scenes/Shop/Conditions/EveryNShotCondition.gd")

const EffectClass = preload("res://Scenes/Shop/Effects/Effect.gd")
const DamageModifierClass = preload("res://Scenes/Shop/Effects/DamageModifier.gd")
const SpeedModifierClass = preload("res://Scenes/Shop/Effects/SpeedModifier.gd")
const FuelModifierClass = preload("res://Scenes/Shop/Effects/FuelModifier.gd")
const ArmorModifierClass = preload("res://Scenes/Shop/Effects/ArmorModifier.gd")
const ExplodingBulletsClass = preload("res://Scenes/Shop/Effects/ExplodingBullets.gd")
const FireTrailClass = preload("res://Scenes/Shop/Effects/FireTrail.gd")

const EFFECT_TYPES := [
	DamageModifierClass,
	SpeedModifierClass,
	FuelModifierClass,
	ArmorModifierClass,
	ExplodingBulletsClass,
	FireTrailClass,
]

const CONDITION_TYPES := [
	SpeedConditionClass,
	EveryNShotConditionClass,
]

const EFFECT_DESERIALIZERS := {
	EffectClass.resource_path: EffectClass,
	"Effect": EffectClass,
	DamageModifierClass.resource_path: DamageModifierClass,
	"DamageModifier": DamageModifierClass,
	SpeedModifierClass.resource_path: SpeedModifierClass,
	"SpeedModifier": SpeedModifierClass,
	FuelModifierClass.resource_path: FuelModifierClass,
	"FuelModifier": FuelModifierClass,
	ArmorModifierClass.resource_path: ArmorModifierClass,
	"ArmorModifier": ArmorModifierClass,
	ExplodingBulletsClass.resource_path: ExplodingBulletsClass,
	"ExplodingBullets": ExplodingBulletsClass,
	FireTrailClass.resource_path: FireTrailClass,
	"FireTrail": FireTrailClass,
}

const CONDITION_DESERIALIZERS := {
	ConditionClass.resource_path: ConditionClass,
	"Condition": ConditionClass,
	SpeedConditionClass.resource_path: SpeedConditionClass,
	"SpeedCondition": SpeedConditionClass,
	EveryNShotConditionClass.resource_path: EveryNShotConditionClass,
	"EveryNShotCondition": EveryNShotConditionClass,
}

var effects: Array[Effect] = []
var weapon: Weapon = null
var condition: Condition = null

func get_price() -> float:
	var result := 0.0
	for e in effects:
		result += e.price

	if condition:
		result += condition.price

	return result

func serialize() -> Dictionary:
	var data: Dictionary = {}
	data.effects = []
	for e in effects:
		data.effects.append(e.serialize())

	if condition != null:
		data.condition = condition.serialize()
	else:
		data.condition = null
	return data

static func deserialize(data: Dictionary) -> Upgrade:
	var upgrade := Upgrade.new()
	for e_data in data.get("effects", []):
		var effect := Upgrade._deserialize_effect(e_data)
		if effect != null:
			upgrade.effects.append(effect)

	var condition_data = data.get("condition")
	if condition_data != null:
		upgrade.condition = Upgrade._deserialize_condition(condition_data)

	return upgrade

static func _deserialize_effect(data: Dictionary) -> Effect:
	var type_identifier: String = data.get("type", "")
	if type_identifier in EFFECT_DESERIALIZERS:
		return EFFECT_DESERIALIZERS[type_identifier].deserialize(data)
	var fallback: String = data.get("class_name", "")
	if fallback in EFFECT_DESERIALIZERS:
		return EFFECT_DESERIALIZERS[fallback].deserialize(data)
	return EffectClass.deserialize(data)

static func _deserialize_condition(data: Dictionary) -> Condition:
	var type_identifier: String = data.get("type", "")
	if type_identifier in CONDITION_DESERIALIZERS:
		return CONDITION_DESERIALIZERS[type_identifier].deserialize(data)
	var fallback: String = data.get("class_name", "")
	if fallback in CONDITION_DESERIALIZERS:
		return CONDITION_DESERIALIZERS[fallback].deserialize(data)
	return ConditionClass.deserialize(data)

static func get_random_upgrade() -> Upgrade:
	var result := Upgrade.new()
	var n_effects: int = [1, 1, 1, 1, 2, 2, 3].pick_random()
	var n_conditions: int = [0, 0, 0, 1].pick_random()

	for i in range(n_effects):
		result.effects.push_back(get_random_effect())

	if n_conditions > 0:
		result.condition = get_random_condition()

	return result

static func get_random_condition() -> Condition:
	if CONDITION_TYPES.is_empty():
		return null
	var condition_type = CONDITION_TYPES.pick_random()
	return condition_type.build_condition()

static func get_random_effect() -> Effect:
	if EFFECT_TYPES.is_empty():
		return null
	var effect_type = EFFECT_TYPES.pick_random()
	return effect_type.build_random()

static func get_color(value):
	return UpgradeUtilsClass.get_color(value)
