class_name ViewFactory
extends RefCounted

func create_view(packed_scene: PackedScene) -> Node:
	return packed_scene.instantiate()
