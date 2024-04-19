class_name PauseTrayEntryUI extends HBoxContainer


@export var _l_pause_num: Label
@export var _l_pause_time: Label
@export var _l_resume_time: Label


func set_pause_num(text: String) -> void:
	_l_pause_num.text = text


func set_pause_time(time: StringName) -> void:
	_l_pause_time.text = time


func set_resume_time(time: StringName) -> void:
	_l_resume_time.text = time
