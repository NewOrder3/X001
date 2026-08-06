class_name ResourceRibbon
extends PanelContainer

## Compact read-only resource HUD for the play view.

@onready var _wood_value: Label = %WoodValue
@onready var _fish_value: Label = %FishValue
@onready var _change_label: Label = %ResourceChangeLabel

var _session: GameSession = null
var _last_amounts: Dictionary[StringName, int] = {}
var _change_timer: Timer = null


func _ready() -> void:
	_change_timer = Timer.new()
	_change_timer.one_shot = true
	_change_timer.timeout.connect(_change_label.hide)
	add_child(_change_timer)
	_apply_style()
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var inventory: InventorySystem = _session.get_inventory_system()
		if not inventory.item_amount_changed.is_connected(_on_item_amount_changed):
			inventory.item_amount_changed.connect(_on_item_amount_changed)
		_snapshot_amounts()
	_refresh()


func _on_item_amount_changed(item_id: StringName, amount: int) -> void:
	var previous_amount: int = _last_amounts.get(item_id, amount)
	_last_amounts[item_id] = amount
	var change: int = amount - previous_amount
	if change != 0:
		_show_change(item_id, change)
	_refresh()


func _snapshot_amounts() -> void:
	if _session == null:
		return
	for item_id: StringName in [&"item_wood", &"item_raw_fish", &"item_fresh_water", &"item_seawater", &"item_grilled_fish"]:
		_last_amounts[item_id] = _session.get_item_amount(item_id)


func _show_change(item_id: StringName, change: int) -> void:
	if not is_instance_valid(_change_label):
		return
	var definition: ItemDefinition = _session.get_item_definition(item_id) if _session != null else null
	var item_name: String = definition.get_display_name() if definition != null else String(item_id)
	_change_label.text = "%s%s %s" % ["+" if change > 0 else "", change, item_name]
	_change_label.modulate = Color(0.68, 1.0, 0.73, 1.0) if change > 0 else Color(1.0, 0.62, 0.52, 1.0)
	_change_label.show()
	_change_timer.start(1.8)


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
