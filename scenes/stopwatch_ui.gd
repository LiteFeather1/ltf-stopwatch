class_name StopwatchUI extends VBoxContainer


@export var _chrome: Control

@export var _stopwatch: Stopwatch

@export var _b_start: ButtonHoverTip
@export var _b_reset: Button
@export var _b_clipboard: Button

@onready var _window: Window = get_window()


func _ready() -> void:
	_stopwatch.started.connect(_enable_buttons)
	
	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_to_clipboard)

	_window.size_changed.connect(_on_window_size_changed)

	await get_tree().process_frame
	_on_window_size_changed()


func toggle_stopwatch() -> void:
	_b_start.button_pressed = not _b_start.button_pressed


func try_reset_stopwatch() -> void:
	if not _b_reset.disabled:
		_reset_pressed()


func try_copy_to_clipboard() -> void:
	if not _b_clipboard.disabled:
		_copy_to_clipboard()


func restore_last_elapsed_time() -> void:
	_b_start.button_pressed = false
	_enable_buttons()
	_stopwatch.restore_last_elapsed_time()


func _enable_buttons() -> void:
	_b_reset.disabled = false
	_b_clipboard.disabled = false


func _start_toggled(state: bool) -> void:
	_stopwatch.set_state(state)

	if state:
		_b_start.text = "P"
		_b_start.set_tip_name("pause")
	else:
		_b_start.text = "C"
		_b_start.set_tip_name("continue")


func _reset_pressed() -> void:
	_b_reset.disabled = true
	_b_clipboard.disabled = true
	_b_reset.hide_pop_up()

	_stopwatch.reset()

	_b_start.button_pressed = false
	_b_start.text = "S"
	_b_start.set_tip_name("start")


func _copy_to_clipboard() -> void:
	DisplayServer.clipboard_set(_stopwatch.get_time_short())


func _on_window_size_changed() -> void:
	# Scale text to fit size
	var s_x := _window.size.x / float(_window.max_size.x)
	var s_y := _window.size.y / float(size.y + _chrome.size.y * 2)
	var s := minf(s_x, s_y)
	scale = Vector2(s, s)

	# Slight scale buttons
	var b_s := maxf(1.0, 1.75 - s)
	var b_scale = Vector2(b_s, b_s)
	_b_start.scale = b_scale
	_b_reset.scale = b_scale
	_b_clipboard.scale = b_scale
