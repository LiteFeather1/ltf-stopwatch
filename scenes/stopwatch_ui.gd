class_name StopwatchUi extends VBoxContainer


@onready var stopwatch: Stopwatch = %stopwatch

@onready var b_start: Button = %b_start
@onready var b_reset: ButtonPopUp = %b_reset
@onready var b_clipboard: ButtonPopUp = %b_clipboard

@onready var window: Window = get_window()


func _ready() -> void:
	stopwatch.started.connect(_stopwatch_started)
	
	b_start.toggled.connect(_start_toggled)
	b_reset.pressed.connect(_reset_pressed)
	b_clipboard.pressed.connect(_copy_to_clip_board_pressed)

	window.size_changed.connect(_resize)


func _stopwatch_started() -> void:
	b_reset.disabled = false


func _start_toggled(state: bool) -> void:
	stopwatch.set_state(state)

	b_start.text = "P" if state else "C"


func _reset_pressed() -> void:
	b_reset.disabled = true
	b_reset.hide_pop_up()

	stopwatch.reset()

	b_start.button_pressed = false
	b_start.text = "S"


func _copy_to_clip_board_pressed() -> void:
	DisplayServer.clipboard_set(stopwatch.get_time_short())


func _resize() -> void:
	var chrome_size_y := 32.0
	var s_x := window.size.x / float(window.max_size.x)
	var s_y := window.size.y / float(size.y + chrome_size_y)
	var s := minf(s_x, s_y)

	scale = Vector2(s, s)
