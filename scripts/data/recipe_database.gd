class_name RecipeDatabase
extends RefCounted

const RECIPES := {
	"parafuso": {
		"id": "parafuso",
		"entradas": [
			{"item": "aco", "quantidade": 1},
		],
		"saidas": [
			{"item": "parafuso", "quantidade": 15},
		],
		"tempoProducao": 15000,
	},
	"viga": {
		"id": "viga",
		"entradas": [
			{"item": "aco", "quantidade": 5},
		],
		"saidas": [
			{"item": "viga", "quantidade": 1},
		],
		"tempoProducao": 60000,
	},
}


static func get_recipe(recipe_id: String) -> Dictionary:
	return RECIPES.get(recipe_id, {}).duplicate(true)


static func get_all() -> Dictionary:
	return RECIPES.duplicate(true)
