class_name MerchantPanel
extends PanelContainer

## Merchant trade surface. It submits BuyMerchantItemCommand and reads public queries only.

@onready var _offer_list: VBoxContainer = %MerchantOfferList
@onready var _status_label: Label = %MerchantStatusLabel

var _session: GameSession = null


func _ready() -> void:
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var merchant_system: MerchantSystem = _session.get_merchant_system()
		if not merchant_system.merchant_purchase_completed.is_connected(_on_purchase_completed):
			merchant_system.merchant_purchase_completed.connect(_on_purchase_completed)
		var inventory_system: InventorySystem = _session.get_inventory_system()
		if not inventory_system.item_amount_changed.is_connected(_on_inventory_changed):
			inventory_system.item_amount_changed.connect(_on_inventory_changed)
	_refresh()


func _buy(offer_id: StringName) -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(BuyMerchantItemCommand.new(offer_id))
	_status_label.text = result.message
	_refresh()


func _on_purchase_completed(_offer_id: StringName, _item_id: StringName, _amount: int) -> void:
	_refresh()


func _on_inventory_changed(_item_id: StringName, _new_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_offer_list):
		return
	for child: Node in _offer_list.get_children():
		child.queue_free()
	if _session == null or not _session.has_active_state():
		_status_label.text = GameText.get_text(&"ui.merchant.status_initial")
		return
	var merchants: Array[MerchantDefinition] = _session.get_merchants()
	if merchants.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = GameText.get_text(&"ui.merchant.empty")
		_offer_list.add_child(empty_label)
		return
	for merchant: MerchantDefinition in merchants:
		var title: Label = Label.new()
		title.text = GameText.format(&"ui.merchant.title", [merchant.get_display_name()])
		_offer_list.add_child(title)
		var description: Label = Label.new()
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text = merchant.get_description()
		_offer_list.add_child(description)
		for offer: MerchantOfferDefinition in merchant.offers:
			var item: ItemDefinition = _session.get_item_definition(offer.item_id)
			var item_name: String = item.get_display_name() if item != null else String(offer.item_id)
			var stock: int = _session.get_merchant_stock(offer.id)
			var precheck: CommandResult = _session.can_buy_merchant_item(offer.id)
			var button: Button = Button.new()
			button.text = GameText.format(&"ui.merchant.offer", [
				item_name,
				offer.amount,
				_format_cost(offer.cost),
				stock,
			])
			button.disabled = not precheck.succeeded
			button.pressed.connect(_buy.bind(offer.id))
			_offer_list.add_child(button)


func _format_cost(cost: Dictionary[StringName, int]) -> String:
	var entries: PackedStringArray = []
	for item_id: StringName in cost:
		var item: ItemDefinition = _session.get_item_definition(item_id)
		entries.append("%s×%d" % [item.get_display_name() if item != null else String(item_id), cost[item_id]])
	return "、".join(entries)
