class_name BuildingView
extends Node2D

var _instance_id: StringName = &""

func bind_instance(instance_id: StringName) -> void:
	_instance_id = instance_id

func unbind() -> void:
	_instance_id = &""

func get_bound_instance_id() -> StringName:
	return _instance_id
