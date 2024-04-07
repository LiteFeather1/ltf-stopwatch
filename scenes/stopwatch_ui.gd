class_name StopwatchUi extends VBoxContainer


@onready var stopwatch: Stopwatch = %stopwatch

@onready var b_start: Button = %b_start
@onready var b_reset: Button = %b_reset
@onready var b_clipboard: Button = %b_clipboard


func _ready() -> void:
	stopwatch.started.connect(_stopwatch_started)
	
	b_start.toggled.connect(_start_toggled)
	b_reset.pressed.connect(_reset_pressed)
	b_clipboard.pressed.connect(_copy_to_clip_board_pressed)


func _stopwatch_started() -> void:
	b_reset.disabled = false


func _start_toggled(state: bool) -> void:
	b_start.text = "P" if state else "C"


func _reset_pressed() -> void:
	b_start.button_pressed = false
	b_start.text = "S"

	b_reset.disabled = true


func _copy_to_clip_board_pressed() -> void:
	DisplayServer.clipboard_set(stopwatch.get_time_short())