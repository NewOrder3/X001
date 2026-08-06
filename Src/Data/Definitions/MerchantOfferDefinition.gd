class_name MerchantOfferDefinition
extends RefCounted

## Immutable one-way trade offer owned by a merchant. Runtime stock lives in MerchantState.

var id: StringName
var item_id: StringName
var amount: int
var cost: Dictionary[StringName, int]
var stock: int


func _init(
	new_id: StringName,
	new_item_id: StringName,
	new_amount: int,
	new_cost: Dictionary[StringName, int],
	new_stock: int,
) -> void:
	id = new_id
	item_id = new_item_id
	amount = new_amount
	cost = new_cost.duplicate()
	stock = new_stock
