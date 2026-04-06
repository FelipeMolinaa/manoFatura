extends ConfirmationDialog

signal action_selected(worker_id: String, action_id: String)

@onready var worker_name_label: Label = $Margin/VBox/WorkerNameLabel
@onready var reposition_button: Button = $Margin/VBox/ActionsRow/RepositionButton
@onready var point_a_button: Button = $Margin/VBox/ActionsRow/PointAButton
@onready var point_b_button: Button = $Margin/VBox/ActionsRow/PointBButton

var _target_worker: WorkerAgent


func _ready() -> void:
	title = "Configurar funcionario"
	get_ok_button().hide()
	get_cancel_button().text = "Fechar"
	reposition_button.pressed.connect(func() -> void:
		_emit_action("position")
	)
	point_a_button.pressed.connect(func() -> void:
		_emit_action("point_a")
	)
	point_b_button.pressed.connect(func() -> void:
		_emit_action("point_b")
	)


func show_for_worker(worker: WorkerAgent) -> void:
	if worker == null or not is_instance_valid(worker):
		return

	_target_worker = worker
	worker_name_label.text = worker.worker_name
	popup_centered()


func _emit_action(action_id: String) -> void:
	if _target_worker == null or not is_instance_valid(_target_worker):
		return

	hide()
	action_selected.emit(_target_worker.worker_id, action_id)
