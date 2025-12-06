extends Node

@export var STARTING_FUEL := 25000.0

@export var fuel: float = STARTING_FUEL:
	set(value):
		fuel = clamp(value, 0, max_fuel)
@export var max_fuel: float = STARTING_FUEL:
	set(value):
		max_fuel = value
		fuel = clamp(fuel, 0, max_fuel)
	get():
		var result = max_fuel
		var fuel_upgrades = PlayerState.get_active_effects_by_type("FuelModifier")
		if fuel_upgrades.size() != 0:
			result += fuel_upgrades.reduce(func(acc, e): return acc + e.flatValue, 0.0)
			result *= 1 + fuel_upgrades.reduce(func(acc, e): return acc + e.percentageValue, 0.0) / 100
		return result
	
@export var fuel_decay_rate := 1.0

@export var money := 1000.0

var upgrade_list: Array[Upgrade] = [debug_upgrade()]

@export var shot_number: int = 0
@export var engine_force: float = 0.0
@export var current_speed: float = 0.0

var synchronizer := MultiplayerSynchronizer.new()

func _ready() -> void:
	var config := SceneReplicationConfig.new()
	
	config.add_property(":shot_number")
	config.add_property(":current_speed")
	config.add_property(":money")
	config.add_property(":fuel")
	config.add_property(":max_fuel")
	
	synchronizer.replication_config = config
	synchronizer.root_path = get_path()
	
	add_child(synchronizer, true)

func debug_upgrade():
	var result: Upgrade = Upgrade.new()
	var cond: EveryNShotCondition = EveryNShotCondition.new()
	cond.frequency = 3
	result.condition = cond
	var eff := ExplodingBullets.new()
	eff.radius = 5.0
	eff.damage = 50.0
	result.effects = [eff]
	return result

func get_active_upgrades_with_effect(effect_class_name) -> Array[Upgrade]:
	return upgrade_list.filter(func(upgrade: Upgrade):
		for e in upgrade.effects:
			if e is Effect and is_instance_of_string(e, effect_class_name):
				if upgrade.condition == null:
					return true
				
				if upgrade.condition is EveryNShotCondition:
					return upgrade.condition.check(shot_number)
				
				if upgrade.condition is SpeedCondition:
					return upgrade.condition.check(PlayerState.engine_force)
				
				return true
				
		return false
	)

func get_active_effects_by_type(effect_class_name):
	var upgrades: Array[Upgrade] = get_active_upgrades_with_effect(effect_class_name)
	var result = []
	for u in upgrades:
		for e in u.effects:
				if e is Effect and is_instance_of_string(e, effect_class_name):
					result.push_back(e)
	
	return result

static func is_instance_of_string(obj : Object, given_class_name : String) -> bool:
	if ClassDB.class_exists(given_class_name):
		# We have a build in class
		return obj.is_class(given_class_name)
	else:
		# We don't have a build in class
		# It must be a script class
		var class_script : Script
		# Assume it is a script path and try to load it
		if ResourceLoader.exists(given_class_name):
			class_script = load(given_class_name) as Script
			
		if class_script == null:
			# Assume it is a class name and try to find it
			for x in ProjectSettings.get_global_class_list():
				
				if str(x["class"]) == given_class_name:
					class_script = load(str(x["path"]))
					break
				
		if class_script == null:
			# Unknown class
			return false
		
		# Get the script of the object and try to match it
		var check_script : Script = obj.get_script()
		while check_script != null:
			if check_script == class_script:
				return true
			
			check_script = check_script.get_base_script()
		
		# Match not found
		return false
