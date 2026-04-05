class_name EntityDatabase
extends RefCounted

const ENTITIES := {
	"maquina": {
		"id": "maquina",
		"nome": "Maquina",
		"tamanho": Vector2i(2, 2),
		"valorCompra": null,
		"valorVenda": null,
		"sprite": null,
		"cor": Color("3b82f6"),
	},
	"bau": {
		"id": "bau",
		"nome": "Bau",
		"tamanho": Vector2i(2, 2),
		"valorCompra": null,
		"valorVenda": null,
		"sprite": null,
		"cor": Color("d97706"),
	},
	"fonte_aco": {
		"id": "fonte_aco",
		"nome": "Fonte de Aco",
		"tamanho": Vector2i(2, 2),
		"valorCompra": null,
		"valorVenda": null,
		"sprite": null,
		"cor": Color("10b981"),
	},
	"vendedor": {
		"id": "vendedor",
		"nome": "Vendedor",
		"tamanho": Vector2i(2, 2),
		"valorCompra": null,
		"valorVenda": null,
		"sprite": null,
		"cor": Color("ef4444"),
	},
}


static func get_entity(entity_id: String) -> Dictionary:
	return ENTITIES.get(entity_id, {}).duplicate(true)


static func get_all() -> Dictionary:
	return ENTITIES.duplicate(true)
