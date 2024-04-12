class_name ChromeUI extends Panel


@export var _window_margin_when_pinning := Vector2i(-32, 32)

var _start_drag_pos: Vector2

var _previous_window_size: Vector2i
var _previous_window_position: Vector2i

@onready var _b_close: ButtonPopUp = %b_close_window
@onready var _b_pin: ButtonPopUp = %b_pin

@onready var _l_title: Label = %l_title

@onready var _window: Window = get_window()


func _ready() -> void:
	set_process(false)

	gui_input.connect(_on_gui_input)

	_b_close.pressed.connect(_close_window)
	_b_pin.toggled.connect(_toggle_pin_window)
	%b_minimise_window.pressed.connect(minimise_window)

	_window.size_changed.connect(_window_size_changed)

	_l_title.text = ProjectSettings.get_setting("application/config/name")


func _process(_delta: float) -> void:
	_window.position += Vector2i(get_global_mouse_position() - _start_drag_pos)


func toggle_pin_input() -> void:
	_b_pin.button_pressed = not _b_pin.button_pressed


func minimise_window() -> void:
	_window.mode = Window.MODE_MINIMIZED


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process(not is_processing())
		_start_drag_pos = get_local_mouse_position()


func _close_window() -> void:
	get_tree().quit()


func _toggle_pin_window(pinning: bool) -> void:
	if pinning:
		_b_pin.text = "nP"
		_b_pin.set_pop_up_name("unpin")

		_previous_window_position = _window.position

		_previous_window_size = _window.size
		_window.size = _window.min_size

		var win_id := _window.current_screen
		var right := DisplayServer.screen_get_position(win_id).x\
				+ DisplayServer.screen_get_size(win_id).x\
				- _window.size.x\
				+ _window_margin_when_pinning.x
		
		_window.position = Vector2i(right, _window_margin_when_pinning.y)
	else:
		_b_pin.text = "P"
		_b_pin.set_pop_up_name("pin")

		_window.size = _previous_window_size
		_window.position = _previous_window_position
	
	_b_close.visible = not pinning
	_window.always_on_top = pinning


func _window_size_changed() -> void:
	await get_tree().process_frame
	_l_title.visible = _l_title.global_position.x + _l_title.size.x - _b_pin.global_position.x < 0.0
