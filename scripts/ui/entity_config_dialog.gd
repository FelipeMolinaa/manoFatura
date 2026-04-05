extends ConfirmationDialog

const EntityDatabase = preload("res://scripts/data/entity_database.gd")
const RecipeDatabase = preload("res://scripts/data/recipe_database.gd")

@onready var entity_name_label: Label = $Margin/VBox/EntityNameLabel
@onready var recipe_row: HBoxContainer = $Margin/VBox/RecipeRow
@onready var recipe_option_button: OptionButton = $Margin/VBox/RecipeRow/RecipeOptionButton
@onready var empty_state_label: Label = $Margin/VBox/EmptyStateLabel

var _target_entity: Node2D
var _recipe_ids: Array[String] = []


func _ready() -> void:
	title = "Configurar entidade"
	get_ok_button().text = "Salvar"
	get_cancel_button().text = "Fechar"
	confirmed.connect(_on_confirmed)


func show_for_entity(entity: Node2D) -> void:
	if not is_instance_valid(entity):
		return

	_target_entity = entity
	var entity_id: String = entity.get_meta("entity_id", "")
	var entity_definition := EntityDatabase.get_entity(entity_id)

	entity_name_label.text = entity_definition.get("nome", "Entidade")
	_configure_recipe_options(entity_id)
	popup_centered()


func _configure_recipe_options(entity_id: String) -> void:
	_recipe_ids.clear()
	recipe_option_button.clear()

	if entity_id != "maquina":
		recipe_row.visible = false
		empty_state_label.visible = true
		empty_state_label.text = "Esta entidade nao possui configuracoes editaveis no momento."
		return

	recipe_row.visible = true
	empty_state_label.visible = false

	var recipe_ids: Array = RecipeDatabase.get_all().keys()
	recipe_ids.sort()

	for recipe_id in recipe_ids:
		var recipe := RecipeDatabase.get_recipe(recipe_id)
		_recipe_ids.append(recipe_id)
		recipe_option_button.add_item(recipe.get("id", recipe_id).capitalize())

	var current_recipe_id: String = _target_entity.get_meta("recipe_id", "parafuso")
	var selected_index := maxi(_recipe_ids.find(current_recipe_id), 0)
	recipe_option_button.select(selected_index)


func _on_confirmed() -> void:
	if not is_instance_valid(_target_entity):
		return

	var entity_id: String = _target_entity.get_meta("entity_id", "")
	if entity_id != "maquina" or _recipe_ids.is_empty():
		return

	var selected_recipe_id := _recipe_ids[recipe_option_button.selected]
	_target_entity.set_meta("recipe_id", selected_recipe_id)

	if _target_entity.has_method("set_secondary_label"):
		var recipe := RecipeDatabase.get_recipe(selected_recipe_id)
		_target_entity.set_secondary_label(recipe.get("id", selected_recipe_id).capitalize())
