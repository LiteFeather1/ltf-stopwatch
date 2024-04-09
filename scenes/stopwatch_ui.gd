class_name StopwatchUi extends VBoxContainer


@onready var _stopwatch: Stopwatch = %stopwatch

@onready var _b_start: ButtonPopUp = %b_start
@onready var _b_reset: ButtonPopUp = %b_reset
@onready var _b_clipboard: ButtonPopUp = %b_clipboard

@onready var _window: Window = get_window()


func _ready() -> void:
	_stopwatch.started.connect(_stopwatch_started)
	
	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_to_clip_board_pressed)

	_window.size_changed.connect(_resize)


func _stopwatch_started() -> void:
	_b_reset.disabled = false


func _start_toggled(state: bool) -> void:
	_stopwatch.set_state(state)

	if state:
		_b_start.text = "P"
		_b_start.set_pop_up_name("pause")
	else:
		_b_start.text = "C"
		_b_start.set_pop_up_name("continue")


func _reset_pressed() -> void:
	_b_reset.disabled = true
	_b_reset.hide_pop_up()

	_stopwatch.reset()

	_b_start.button_pressed = false
	_b_start.text = "S"
	_b_start.set_pop_up_name("start")


func _copy_to_clip_board_pressed() -> void:
	DisplayServer.clipboard_set(_stopwatch.get_time_short())


func _resize() -> void:
	var chrome_size_y := 32.0
	var s_x := _window.size.x / float(_window.max_size.x)
	var s_y := _window.size.y / float(size.y + chrome_size_y)
	var s := minf(s_x, s_y)

	scale = Vector2(s, s)
