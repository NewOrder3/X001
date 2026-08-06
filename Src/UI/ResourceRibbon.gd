class_name ResourceRibbon
extends PanelContainer

## Compact read-only resource HUD for the play view.

@onready var _wood_value: Label = %WoodValue
@onready var _fish_value: Label = %FishValue

var _session: GameSession = null


func _ready() -> void:
	_apply_style()
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var inventory: InventorySystem = _session.get_inventory_system()
		if not inventory.item_amount_changed.is_connected(_on_item_amount_changed):
			inventory.item_amount_changed.connect(_on_item_amount_changed)
	_refresh()


func _on_item_amount_changed(_item_id: StringName, _amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_wood_value):
		return
	var wood: int = _session.get_item_amount(&"item_wood") if _session != null else 0
	var fish: int = _session.get_item_amount(&"item_raw_fish") if _session != null else 0
	_wood_value.text = "木材  %d" % wood
	_fish_value.text = "食物  %d" % fish


func _apply_style() -> void:
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color("b96e2a")
	background.corner_radius_top_left = 18
	background.corner_radius_top_right = 18
	background.corner_radius_bottom_right = 18
	background.corner_radius_bottom_left = 18
	background.border_width_left = 3
	background.border_width_top = 3
	background.border_width_right = 3
	background.border_width_bottom = 3
	background.border_color = Color("6d3d20")
	add_theme_stylebox_override(&"panel", background)
