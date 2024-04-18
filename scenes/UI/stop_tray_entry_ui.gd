class_name StopTrayEntryUI extends HBoxContainer


@export var _l_stop: Label
@export var _l_stop_time: Label
@export var _l_resume_time: Label


func set_stop_num(text: String) -> void:
	_l_stop.text = text


func set_stop_time() -> void:
	_l_stop_time.text = _get_current_time()


func set_resume_time() -> void:
	_l_resume_time.text = _get_current_time()


func _get_current_time() -> String:
	var current_time := Time.get_datetime_dict_from_system()
	return "%s:%s:%s" % [
		current_time["hour"],
		current_time["minute"],
		current_time["second"]
	]
