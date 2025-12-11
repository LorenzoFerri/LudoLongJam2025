@tool
extends Node3D

@export var radius: float = 1.0
@export var scale_factor: float = 1.0
var cloud_material: ParticleProcessMaterial
var spark_material: ParticleProcessMaterial
var flare_material: ParticleProcessMaterial

@onready var vfx_clouds: GPUParticles3D = $VFX_Clouds
@export var vfx_clouds_base_scale: float
@export var vfx_clouds_base_radial_velocity: float
@onready var vfx_sparks: GPUParticles3D = $VFX_Sparks
@export var vfx_sparks_base_scale: float
@export var vfx_sparks_base_initial_velocity: float
@onready var vfx_flare: GPUParticles3D = $VFX_Flare
@export var vfx_flare_base_scale: float
@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@export var light_range: float = 3.3

func _ready():
	cloud_material = vfx_clouds.process_material as ParticleProcessMaterial
	spark_material = vfx_sparks.process_material as ParticleProcessMaterial
	flare_material = vfx_flare.process_material as ParticleProcessMaterial

func _process(_delta: float) -> void:
	if cloud_material:
		cloud_material.scale_min = vfx_clouds_base_scale * radius * scale_factor
		cloud_material.scale_max = vfx_clouds_base_scale * radius * scale_factor * 18/17
		cloud_material.radial_velocity_min = vfx_clouds_base_radial_velocity * radius * scale_factor
		cloud_material.radial_velocity_max = vfx_clouds_base_radial_velocity * radius * scale_factor * 15/13
	if spark_material:
		spark_material.scale_min = vfx_sparks_base_scale * radius * scale_factor
		spark_material.scale_max = vfx_sparks_base_scale * radius * scale_factor * 1.4
		spark_material.initial_velocity_min = vfx_sparks_base_initial_velocity * radius * scale_factor
		spark_material.initial_velocity_max = vfx_sparks_base_initial_velocity * radius * scale_factor * 2
	if flare_material:
		flare_material.scale_min = vfx_flare_base_scale * radius * scale_factor
		flare_material.scale_max = vfx_flare_base_scale * radius * scale_factor 
	if omni_light_3d:
		omni_light_3d.range = light_range * radius * scale_factor
