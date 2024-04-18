class_name StopTrayEntryUI extends HBoxContainer


@export var _l_stop: Label
@export var _l_stop_time: Label
@export var _l_resume_time: Label


func set_stop(text: String) -> void:
	_l_stop.text = text


func set_stop_time(time: StringName) -> void:
	_l_stop_time.text = time


func set_resume_time(time: StringName) -> void:
	_l_resume_time.text = time
