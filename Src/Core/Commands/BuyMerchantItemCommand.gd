class_name BuyMerchantItemCommand
extends GameCommand

## Requests one merchant purchase. MerchantSystem owns validation and atomic exchange.

var offer_id: StringName


func _init(new_offer_id: StringName) -> void:
	offer_id = new_offer_id


func get_command_type() -> StringName:
	return &"buy_merchant_item"
