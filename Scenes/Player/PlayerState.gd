extends Node

@export var STARTING_FUEL := 25000.0

@export var fuel: float = STARTING_FUEL:
	set(value):
		fuel = clamp(value, 0, max_fuel)
@export var max_fuel: float = STARTING_FUEL:
	set(value):
		max_fuel = value
		fuel = clamp(fuel, 0, max_fuel)
@export var fuel_decay_rate := 1.0

var money := 0.0

var upgrade_list: Array[Upgrade] = []
