class_name PauseTrayEntryUI extends HBoxContainer


signal deleted(index: int)


@export var _l_pause_num: Label
@export var _l_pause_time: Label
@export var _l_resume_time: Label


func _ready() -> void:
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event\
		and mb_event.button_index == MOUSE_BUTTON_LEFT\
		and mb_event.is_released()\
		and get_rect().has_point(mb_event.position):
			print("Delete")


func set_pause_num(text: String) -> void:
	_l_pause_num.text = text


func set_pause_time(time: StringName) -> void:
	_l_pause_time.text = time


func set_resume_time(time: StringName) -> void:
	_l_resume_time.text = time


func set_resume_time_empty() -> void:
	_l_resume_time.text = "--:--:--"
