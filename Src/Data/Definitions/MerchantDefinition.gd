class_name MerchantDefinition
extends RefCounted

## Immutable merchant template with a fixed offer list. No runtime values here.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var offers: Array[MerchantOfferDefinition]


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_offers: Array[MerchantOfferDefinition],
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	offers = new_offers.duplicate()


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
