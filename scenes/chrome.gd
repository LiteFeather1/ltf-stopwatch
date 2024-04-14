class_name ChromeUI extends Panel


signal close_pressed()


const WINDOW_SIZE := &"window_size"
const WINDOW_PINNED_SIZE := &"window_pinnned_size"
const WINDOW_POSITION := &"window_position"

@export var _window_margin_when_pinning := Vector2i(-32, 32)

var _start_drag_pos: Vector2

var _previous_window_size: Vector2i
var _previous_window_pinned_size: Vector2i
var _previous_window_position: Vector2i

@onready var _b_close: Button = %b_close_window
@onready var _b_pin: ButtonHoverTip = %b_pin

@onready var _l_title: Label = %l_title

@onready var _window: Window = get_window()


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process(false)

	gui_input.connect(_on_gui_input)

	_b_close.pressed.connect(_close_window)
	_b_pin.toggled.connect(_toggle_pin_window)
	%b_minimise_window.pressed.connect(minimise_window)

	_window.size_changed.connect(_window_size_changed)

	_l_title.text = ProjectSettings.get_setting("application/config/name")

	await get_tree().process_frame
	if _previous_window_pinned_size == Vector2i.ZERO: 
		_previous_window_pinned_size = _window.min_size


func _process(_delta: float) -> void:
	_window.position += Vector2i(get_global_mouse_position() - _start_drag_pos)


func toggle_pin_input() -> void:
	_b_pin.button_pressed = not _b_pin.button_pressed


func minimise_window() -> void:
	_window.mode = Window.MODE_MINIMIZED


func save(save_data: Dictionary) -> void:
	if _b_pin.button_pressed:
		save_data[WINDOW_SIZE] = var_to_str(_previous_window_size)
		save_data[WINDOW_PINNED_SIZE] = var_to_str(_window.size)
		save_data[WINDOW_POSITION] = var_to_str(_previous_window_position)
	else:
		save_data[WINDOW_SIZE] = var_to_str(_window.size)
		save_data[WINDOW_PINNED_SIZE] = var_to_str(_previous_window_pinned_size)
		save_data[WINDOW_POSITION] = var_to_str(_window.position)


func load(save_data: Dictionary) -> void:
	if save_data.has(WINDOW_SIZE):
		_previous_window_size = str_to_var(save_data[WINDOW_SIZE])
		_window.size = _previous_window_size

	_previous_window_pinned_size = str_to_var(save_data[WINDOW_PINNED_SIZE])\
			if save_data.has(WINDOW_PINNED_SIZE) else _window.min_size
	
	if save_data.has(WINDOW_POSITION):
		_previous_window_position = str_to_var(save_data[WINDOW_POSITION])
		_window.position = _previous_window_position


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process(not is_processing())
		_start_drag_pos = get_local_mouse_position()


func _close_window() -> void:
	close_pressed.emit()


func _toggle_pin_window(pinning: bool) -> void:
	if pinning:
		_b_pin.text = "nP"
		_b_pin.set_tip_name("unpin")

		_previous_window_position = _window.position

		_previous_window_size = _window.size
		_window.size = _previous_window_pinned_size

		var win_id := _window.current_screen
		var right := DisplayServer.screen_get_position(win_id).x\
				+ DisplayServer.screen_get_size(win_id).x\
				- _window.size.x\
				+ _window_margin_when_pinning.x
		
		_window.position = Vector2i(right, _window_margin_when_pinning.y)

	else:
		_b_pin.text = "P"
		_b_pin.set_tip_name("pin")

		_previous_window_pinned_size = _window.size
		_window.size = _previous_window_size

		_window.position = _previous_window_position
	
	_b_close.visible = not pinning
	_window.always_on_top = pinning


func _window_size_changed() -> void:
	await get_tree().process_frame
	_l_title.visible = _l_title.global_position.x + _l_title.size.x - _b_pin.global_position.x < 0.0
