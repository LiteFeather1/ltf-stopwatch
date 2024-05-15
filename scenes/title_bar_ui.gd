class_name TitleBarUI extends Panel


signal close_pressed()


const WINDOW_SIZE := &"window_size"
const WINDOW_PINNED_SIZE := &"window_pinnned_size"
const WINDOW_POSITION := &"window_position"

const HOVER := &"hover"
const PRESSED := &"pressed"

@export var _window_margin_when_pinning := Vector2i(-32, 32)

@export var _l_title: Label

@export var _b_close: Button
@export var _b_minimise: Button

@export_category("Button Pin")
@export var _b_pin: ButtonHoverTip
@export var _sprite_pin: Texture2D
@export var _sprite_unpin: Texture2D

var _start_drag_pos: Vector2

var _previous_window_size: Vector2i
var _previous_window_pinned_size: Vector2i
var _previous_window_position: Vector2i


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process_input(false)

	_b_close.pressed.connect(_close_window)
	_b_pin.toggled.connect(_toggle_pin_window)
	_b_minimise.pressed.connect(_minimise_window)

	GLOBAL.window.size_changed.connect(_window_size_changed)

	_l_title.text = ProjectSettings.get_setting("application/config/name")

	_b_minimise.add_theme_stylebox_override(
		HOVER, _b_minimise.get_theme_stylebox(HOVER).duplicate()
	)
	_b_minimise.add_theme_stylebox_override(
		PRESSED, _b_minimise.get_theme_stylebox(PRESSED).duplicate()
	)

	await get_tree().process_frame
	
	if _previous_window_pinned_size == Vector2i.ZERO:
		_previous_window_pinned_size = GLOBAL.window.min_size


func _input(event: InputEvent) -> void:
	var m_event := event as InputEventMouse
	if m_event:
		GLOBAL.window.position += Vector2i(m_event.position - _start_drag_pos)


func _gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process_input(not is_processing_input())
		_start_drag_pos = mb_event.position


func load(save_data: Dictionary) -> void:
	if save_data.has(WINDOW_SIZE):
		_previous_window_size = str_to_var(save_data[WINDOW_SIZE])
		GLOBAL.window.size = _previous_window_size

	_previous_window_pinned_size = str_to_var(save_data[WINDOW_PINNED_SIZE])\
		if save_data.has(WINDOW_PINNED_SIZE) else GLOBAL.window.min_size
	
	if save_data.has(WINDOW_POSITION):
		_previous_window_position = str_to_var(save_data[WINDOW_POSITION])
		GLOBAL.window.position = _previous_window_position


func save(save_data: Dictionary) -> void:
	if _b_pin.button_pressed:
		save_data[WINDOW_SIZE] = var_to_str(_previous_window_size)
		save_data[WINDOW_PINNED_SIZE] = var_to_str(GLOBAL.window.size)
		save_data[WINDOW_POSITION] = var_to_str(_previous_window_position)
	else:
		save_data[WINDOW_SIZE] = var_to_str(GLOBAL.window.size)
		save_data[WINDOW_PINNED_SIZE] = var_to_str(_previous_window_pinned_size)
		save_data[WINDOW_POSITION] = var_to_str(GLOBAL.window.position)


func _close_window() -> void:
	close_pressed.emit()


func _toggle_pin_window(pinning: bool) -> void:
	_b_close.visible = not pinning
	GLOBAL.window.always_on_top = pinning

	if pinning:
		_b_pin.icon = _sprite_unpin
		_b_pin.set_tip_name("unpin")

		_set_minimise_corner_radius(_b_close.get_theme_stylebox(HOVER).corner_radius_top_right)

		_previous_window_position = GLOBAL.window.position

		_previous_window_size = GLOBAL.window.size
		GLOBAL.window.size = _previous_window_pinned_size

		var win_id := GLOBAL.window.current_screen
		var right := (
			DisplayServer.screen_get_position(win_id).x
			+ DisplayServer.screen_get_size(win_id).x
			- GLOBAL.window.size.x
			+ _window_margin_when_pinning.x
		)
		
		GLOBAL.window.position = Vector2i(right, _window_margin_when_pinning.y)
	else:
		_b_pin.icon = _sprite_pin
		_b_pin.set_tip_name("pin")

		_set_minimise_corner_radius(_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_left)

		_previous_window_pinned_size = GLOBAL.window.size
		GLOBAL.window.size = _previous_window_size
		
		GLOBAL.window.position = _previous_window_position


func _minimise_window() -> void:
	GLOBAL.window.mode = Window.MODE_MINIMIZED


func _window_size_changed() -> void:
	await get_tree().process_frame
	
	_l_title.visible = 0.0 > (
		_l_title.global_position.x + _l_title.size.x - _b_pin.global_position.x
	)


func _set_minimise_corner_radius(radius: int) -> void:
	_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_right = radius
	_b_minimise.get_theme_stylebox(PRESSED).corner_radius_top_right = radius
