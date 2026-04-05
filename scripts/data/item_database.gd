class_name ItemDatabase
extends RefCounted

const ITEMS := {
	"aco": {
		"id": "aco",
		"nome": "Aco",
		"peso": 1.0,
		"valorVenda": 50,
		"valorCompra": 75,
		"sprite": null,
		"cor": Color("94a3b8"),
	},
	"parafuso": {
		"id": "parafuso",
		"nome": "Parafuso",
		"peso": 0.001,
		"valorVenda": 5,
		"valorCompra": 10,
		"sprite": null,
		"cor": Color("f59e0b"),
	},
	"viga": {
		"id": "viga",
		"nome": "Viga",
		"peso": 5.0,
		"valorVenda": 25,
		"valorCompra": 35,
		"sprite": null,
		"cor": Color("f97316"),
	},
}


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {}).duplicate(true)


static func get_all() -> Dictionary:
	return ITEMS.duplicate(true)
