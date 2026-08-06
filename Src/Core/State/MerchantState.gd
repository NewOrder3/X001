class_name MerchantState
extends RefCounted

## Serializable merchant runtime stock. MerchantSystem owns all gameplay mutation.

var stock_remaining: Dictionary[StringName, int] = {}


func to_save_data() -> Dictionary:
	var stock: Dictionary[String, int] = {}
	for offer_id: StringName in stock_remaining:
		stock[String(offer_id)] = stock_remaining[offer_id]
	return {"stock_remaining": stock}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		stock_remaining.clear()
		return true
	var raw_stock: Variant = data.get("stock_remaining")
	if not raw_stock is Dictionary:
		return false
	var loaded_stock: Dictionary[StringName, int] = {}
	for raw_offer_id: Variant in raw_stock:
		if typeof(raw_offer_id) != TYPE_STRING:
			return false
		var raw_amount: Variant = raw_stock[raw_offer_id]
		if typeof(raw_amount) != TYPE_INT and typeof(raw_amount) != TYPE_FLOAT:
			return false
		var amount: float = float(raw_amount)
		if amount < 0.0 or amount != floor(amount):
			return false
		loaded_stock[StringName(raw_offer_id)] = int(amount)
	stock_remaining = loaded_stock
	return true
