extends ConfirmationDialog

signal action_confirmed(action_id: String)

var _pending_action_id := ""


func _ready() -> void:
	confirmed.connect(_on_confirmed)


func show_confirmation(action_id: String, title_text: String, message: String, confirm_text := "Confirmar", cancel_text := "Cancelar") -> void:
	_pending_action_id = action_id
	title = title_text
	dialog_text = message
	get_ok_button().text = confirm_text
	get_cancel_button().text = cancel_text
	popup_centered()


func _on_confirmed() -> void:
	if _pending_action_id.is_empty():
		return
	action_confirmed.emit(_pending_action_id)
	_pending_action_id = ""
