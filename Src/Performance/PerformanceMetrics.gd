class_name PerformanceMetrics
extends RefCounted

var frame_time_ms: float = 0.0
var fps: float = 0.0

func sample(delta: float) -> void:
	if delta <= 0.0:
		return
	frame_time_ms = delta * 1000.0
	fps = 1.0 / delta
