class_name GameHudLayout
extends Control

## Keeps HUD panels within the visible viewport and switches to a stacked layout on narrow screens.

const COMPACT_WIDTH: float = 900.0

@export var edge_margin: float = 32.0
@export var panel_gap: float = 16.0

@onready var _left_panel_scroll: ScrollContainer = $LeftPanelScroll
@onready var _survival_hud: Control = $SurvivalHUD


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x < COMPACT_WIDTH:
		_apply_compact_layout(viewport_size)
		return
	_apply_wide_layout(viewport_size)


func _apply_wide_layout(viewport_size: Vector2) -> void:
	var left_width: float = clampf(viewport_size.x * 0.32, 400.0, 468.0)
	var survival_width: float = clampf(viewport_size.x * 0.28, 360.0, 408.0)
	_left_panel_scroll.position = Vector2(edge_margin, edge_margin)
	_left_panel_scroll.size = Vector2(left_width, maxf(0.0, viewport_size.y - edge_margin * 2.0))
	_survival_hud.position = Vector2(viewport_size.x - edge_margin - survival_width, edge_margin)
	_survival_hud.size = Vector2(survival_width, 204.0)


func _apply_compact_layout(viewport_size: Vector2) -> void:
	var content_width: float = maxf(0.0, viewport_size.x - edge_margin * 2.0)
	var survival_height: float = minf(204.0, maxf(132.0, viewport_size.y * 0.28))
	_survival_hud.position = Vector2(edge_margin, edge_margin)
	_survival_hud.size = Vector2(content_width, survival_height)
	var left_top: float = edge_margin + survival_height + panel_gap
	_left_panel_scroll.position = Vector2(edge_margin, left_top)
	_left_panel_scroll.size = Vector2(content_width, maxf(0.0, viewport_size.y - left_top - edge_margin))
