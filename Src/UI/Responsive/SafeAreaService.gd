class_name SafeAreaService
extends RefCounted

func get_content_rect(viewport: Viewport) -> Rect2:
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area.size == Vector2i.ZERO:
		return viewport_rect
	return Rect2(safe_area.position, safe_area.size).intersection(viewport_rect)
