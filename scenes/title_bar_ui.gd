class_name TitleBarUI extends Panel


signal close_pressed()


const NAME := &"TitleBarUI"

const SAVE_KEYS: PackedStringArray = [
	"_window_position",
	"_window_size",
	"_window_pinned_position",
	"_window_pinned_size",
]

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

var _window_position: Vector2i = Vector2i(-1, 1)
var _window_size: Vector2i
var _window_pinned_position: Vector2i
var _window_pinned_size: Vector2i


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
	
	if _window_position.x != -1:
		GLOBAL.window.position = _window_position
		GLOBAL.window.size = _window_size
	else:
		var win_id := GLOBAL.window.current_screen
		_window_pinned_position = Vector2i(
			(
				DisplayServer.screen_get_position(win_id).x
				+ DisplayServer.screen_get_size(win_id).x
				- GLOBAL.window.min_size.x
				+ _window_margin_when_pinning.x
			),
			_window_margin_when_pinning.y,
		)
		_window_pinned_size = GLOBAL.window.min_size



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
	for key: String in SAVE_KEYS:
		self[key] = str_to_var(save_data[key])


func save(save_data: Dictionary) -> void:
	if _b_pin.button_pressed:
		_window_pinned_position = GLOBAL.window.position
		_window_pinned_size = GLOBAL.window.size
	else:
		_window_position = GLOBAL.window.position
		_window_size = GLOBAL.window.size

	for key: String in SAVE_KEYS:
		save_data[key] = var_to_str(self[key])


func _close_window() -> void:
	close_pressed.emit()


func _toggle_pin_window(pinning: bool) -> void:
	_b_close.visible = not pinning
	GLOBAL.window.always_on_top = pinning

	if pinning:
		_b_pin.icon = _sprite_unpin
		_b_pin.set_tip_name("unpin")

		_set_minimise_corner_radius(_b_close.get_theme_stylebox(HOVER).corner_radius_top_right)

		_window_position = GLOBAL.window.position
		_window_size = GLOBAL.window.size

		GLOBAL.window.position = _window_pinned_position
		GLOBAL.window.size = _window_pinned_size
	else:
		_b_pin.icon = _sprite_pin
		_b_pin.set_tip_name("pin")

		_set_minimise_corner_radius(_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_left)

		_window_pinned_position = GLOBAL.window.position
		_window_pinned_size = GLOBAL.window.size
		
		GLOBAL.window.position = _window_position
		GLOBAL.window.size = _window_size


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
