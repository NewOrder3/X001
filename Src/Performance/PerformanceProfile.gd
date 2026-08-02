class_name PerformanceProfile
extends RefCounted

var id: StringName
var particle_multiplier: float
var map_density_multiplier: float
var effects_enabled: bool

func _init(new_id: StringName, new_particle_multiplier: float, new_map_density_multiplier: float, new_effects_enabled: bool) -> void:
	id = new_id
	particle_multiplier = new_particle_multiplier
	map_density_multiplier = new_map_density_multiplier
	effects_enabled = new_effects_enabled
