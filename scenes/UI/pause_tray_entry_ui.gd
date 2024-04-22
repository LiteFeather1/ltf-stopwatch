class_name PauseTrayEntryUI extends HBoxContainer


signal pointer_entered(instance: Control)
signal pointer_exited(instance: Control)
signal deleted(sibbling_index: int)


@export var _l_pause_num: Label
@export var _l_pause_time: Label
@export var _l_resume_time: Label

var _is_mouse_inside := false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _on_mouse_entered() -> void:
	_is_mouse_inside = true
	pointer_entered.emit(self)


func _on_mouse_exited() -> void:
	_is_mouse_inside = false
	pointer_exited.emit(self)


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event\
			and mb_event.button_index == MOUSE_BUTTON_LEFT\
			and mb_event.is_released()\
			and _is_mouse_inside:
		deleted.emit(get_index())
		queue_free()


func set_pause_num(text: String) -> void:
	_l_pause_num.text = text


func set_pause_time(time: StringName) -> void:
	_l_pause_time.text = time


func set_resume_time(time: StringName) -> void:
	_l_resume_time.text = time


func set_resume_time_empty() -> void:
	_l_resume_time.text = "--:--:--"
