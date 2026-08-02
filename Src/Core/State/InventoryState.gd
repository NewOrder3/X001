class_name InventoryState
extends RefCounted

## Serializable item quantities. InventorySystem owns all gameplay mutations.

var item_amounts: Dictionary[StringName, int] = {}


func to_save_data() -> Dictionary:
	var amounts: Dictionary[String, int] = {}
	for item_id: StringName in item_amounts:
		amounts[String(item_id)] = item_amounts[item_id]
	return {"item_amounts": amounts}


func load_from_save_data(data: Dictionary) -> bool:
	var raw_amounts: Variant = data.get("item_amounts", {})
	if not raw_amounts is Dictionary:
		return false

	item_amounts.clear()
	for raw_item_id: Variant in raw_amounts:
		if typeof(raw_item_id) != TYPE_STRING:
			return false
		var raw_amount: Variant = raw_amounts[raw_item_id]
		if typeof(raw_amount) != TYPE_INT and typeof(raw_amount) != TYPE_FLOAT:
			return false
		var amount: float = float(raw_amount)
		if amount < 0.0 or amount != floor(amount):
			return false
		item_amounts[StringName(raw_item_id)] = int(amount)
	return true
