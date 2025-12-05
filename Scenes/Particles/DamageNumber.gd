extends Node3D


@export var lifetime := 1.25
@export var randomness := 0.5
@export var direction := Vector3(randf_range(-randomness, randomness), 1, randf_range(-randomness, randomness)).normalized()
@export var distance := 1.5
@export var damage := 512
@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	label_3d.text = str(damage)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var tween := get_tree().create_tween()
	tween.parallel().tween_property(label_3d, "modulate:a", 0, lifetime)
	tween.parallel().tween_property(self, "position", (position + direction) * distance, lifetime)
	tween.tween_callback(self.queue_free)
