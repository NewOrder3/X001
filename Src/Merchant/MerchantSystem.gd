class_name MerchantSystem
extends RefCounted

## Owns merchant stock and atomic one-way trades. UI never mutates MerchantState.

signal merchant_purchase_completed(offer_id: StringName, item_id: StringName, amount: int)

const ERROR_INVALID_MERCHANT_STATE: StringName = &"invalid_merchant_state"
const ERROR_UNKNOWN_OFFER: StringName = &"unknown_merchant_offer"
const ERROR_INSUFFICIENT_RESOURCES: StringName = &"insufficient_resources"
const ERROR_INVENTORY_FULL: StringName = &"inventory_full"
const ERROR_OUT_OF_STOCK: StringName = &"merchant_out_of_stock"

var _data_registry: DataRegistry
var _inventory_system: InventorySystem


func _init(new_data_registry: DataRegistry, new_inventory_system: InventorySystem) -> void:
	_data_registry = new_data_registry
	_inventory_system = new_inventory_system


func initialize_new_state(state: MerchantState) -> bool:
	if state == null or _data_registry == null:
		return false
	state.stock_remaining.clear()
	for merchant: MerchantDefinition in _data_registry.get_merchants():
		for offer: MerchantOfferDefinition in merchant.offers:
			state.stock_remaining[offer.id] = offer.stock
	return true


func activate_loaded_state(state: MerchantState) -> bool:
	if state == null or _data_registry == null:
		return false
	for merchant: MerchantDefinition in _data_registry.get_merchants():
		for offer: MerchantOfferDefinition in merchant.offers:
			if not state.stock_remaining.has(offer.id):
				state.stock_remaining[offer.id] = offer.stock
			elif state.stock_remaining[offer.id] < 0:
				state.stock_remaining[offer.id] = 0
	return true


func get_stock(state: MerchantState, offer_id: StringName) -> int:
	if state == null or _data_registry == null or not _data_registry.has_merchant_offer(offer_id):
		return 0
	return state.stock_remaining.get(offer_id, _data_registry.get_merchant_offer(offer_id).stock)


func can_buy(state: GameState, offer_id: StringName) -> CommandResult:
	var validation: CommandResult = _validate_purchase(state, offer_id)
	return validation


func buy(state: GameState, offer_id: StringName) -> CommandResult:
	var validation: CommandResult = _validate_purchase(state, offer_id)
	if not validation.succeeded:
		return validation
	var offer: MerchantOfferDefinition = _data_registry.get_merchant_offer(offer_id)
	if not _inventory_system.spend_cost(state.inventory_state, offer.cost):
		return CommandResult.failure(
			ERROR_INSUFFICIENT_RESOURCES,
			GameText.get_text(&"message.merchant.insufficient_resources"),
		)
	state.merchant_state.stock_remaining[offer_id] = state.merchant_state.stock_remaining[offer_id] - 1
	var capacity: int = _inventory_system.get_capacity(state, offer.item_id)
	if not _inventory_system.add(state.inventory_state, offer.item_id, offer.amount, capacity):
		return CommandResult.failure(
			ERROR_INVENTORY_FULL,
			GameText.get_text(&"message.merchant.inventory_full"),
		)
	merchant_purchase_completed.emit(offer_id, offer.item_id, offer.amount)
	return CommandResult.success(
		GameText.format(&"message.merchant.purchased", [offer.amount, _get_item_name(offer.item_id)])
	)


func _validate_purchase(state: GameState, offer_id: StringName) -> CommandResult:
	if state == null or state.merchant_state == null or _data_registry == null or _inventory_system == null:
		return CommandResult.failure(
			ERROR_INVALID_MERCHANT_STATE,
			GameText.get_text(&"message.merchant.unavailable"),
		)
	if not _data_registry.has_merchant_offer(offer_id):
		return CommandResult.failure(
			ERROR_UNKNOWN_OFFER,
			GameText.get_text(&"message.merchant.unknown_offer"),
		)
	var offer: MerchantOfferDefinition = _data_registry.get_merchant_offer(offer_id)
	if get_stock(state.merchant_state, offer_id) <= 0:
		return CommandResult.failure(
			ERROR_OUT_OF_STOCK,
			GameText.get_text(&"message.merchant.out_of_stock"),
		)
	if not _inventory_system.can_afford(state.inventory_state, offer.cost):
		return CommandResult.failure(
			ERROR_INSUFFICIENT_RESOURCES,
			GameText.get_text(&"message.merchant.insufficient_resources"),
		)
	var capacity: int = _inventory_system.get_capacity(state, offer.item_id)
	if not _inventory_system.can_add(state.inventory_state, offer.item_id, offer.amount, capacity):
		return CommandResult.failure(
			ERROR_INVENTORY_FULL,
			GameText.get_text(&"message.merchant.inventory_full"),
		)
	return CommandResult.success("")


func _get_item_name(item_id: StringName) -> String:
	var item: ItemDefinition = _data_registry.get_item(item_id)
	return item.get_display_name() if item != null else String(item_id)
