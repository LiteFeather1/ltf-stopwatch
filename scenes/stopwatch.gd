class_name StopWatch
extends VBoxContainer


@export_multiline var _time_text_template := "[center]%02d:%02d:%02d.[font_size=48]%d[/font_size][/center]"

@export var ticking_colour := Color("f7f7f7")
@export var paused_colour := Color("cecece")

var elapsed_time := 0.0

@onready var _l_time: RichTextLabel = %l_time


func _ready() -> void:
	set_state(false)


func _process(delta: float) -> void:
	elapsed_time += delta
	_set_time()


func set_state(state: bool) -> void:
	set_process(state)
	modulate = ticking_colour if state else paused_colour


func reset() -> void:
	set_process(false)
	modulate = paused_colour
	elapsed_time = 0.0
	_set_time()


func _set_time() -> void:
	_l_time.text = _time_text_template % [
			(elapsed_time / 3600.0),
			(fmod(elapsed_time, 3600.0) / 60.0),
			(fmod(elapsed_time, 60.0)),
			(fmod(elapsed_time, 1) * 100.0)
	]
