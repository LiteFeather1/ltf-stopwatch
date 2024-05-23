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

const LONG_TITLE := "LTF Stopwatch"
const SHORT_TITLE := "LTF"

@export var _window_margin_when_pinning := Vector2i(-32, 32)
@export var _l_title: Label

@export_category("Buttons")
@export var _b_close: Button
@export var _b_minimise: Button

@export_category("Button Pin")
@export var _b_pin: ButtonHoverTip
@export var _sprite_pin: Texture2D
@export var _sprite_unpin: Texture2D

var _width_for_short_title: float

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

	_b_minimise.add_theme_stylebox_override(
		HOVER, _b_minimise.get_theme_stylebox(HOVER).duplicate()
	)
	_b_minimise.add_theme_stylebox_override(
		PRESSED, _b_minimise.get_theme_stylebox(PRESSED).duplicate()
	)

	_width_for_short_title = _l_title.get_theme_font("font").get_string_size(
		_l_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _l_title.get_theme_font_size("font_size"),
	).x + 2.0

	if _window_position.x != -1:
		GLOBAL.window.position = _window_position
		GLOBAL.window.size = _window_size
	else:
		var win_id := GLOBAL.window.current_screen
		_window_pinned_position = Vector2i((
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


func load(save_dict: Dictionary) -> void:
	for key: String in SAVE_KEYS:
		self[key] = str_to_var(save_dict[key])


func save() -> Dictionary:
	if _b_pin.button_pressed:
		_window_pinned_position = GLOBAL.window.position
		_window_pinned_size = GLOBAL.window.size
	else:
		_window_position = GLOBAL.window.position
		_window_size = GLOBAL.window.size

	var save_dict := {}
	for key: String in SAVE_KEYS:
		save_dict[key] = var_to_str(self[key])
	return save_dict


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
		GLOBAL.window.size_changed.connect(_on_window_size_changed)

		# We await a small delay cuz the ui sizing takes time to update
		await GLOBAL.tree.create_timer(.00001).timeout
		_on_window_size_changed()
	else:
		_l_title.text = LONG_TITLE
		GLOBAL.window.size_changed.disconnect(_on_window_size_changed)
		_b_pin.icon = _sprite_pin
		_b_pin.set_tip_name("pin")

		_set_minimise_corner_radius(_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_left)

		_window_pinned_position = GLOBAL.window.position
		_window_pinned_size = GLOBAL.window.size
		
		GLOBAL.window.position = _window_position
		GLOBAL.window.size = _window_size


func _minimise_window() -> void:
	GLOBAL.window.mode = Window.MODE_MINIMIZED


func _set_title(text: String) -> void:
	if _l_title.text[_l_title.text.length() - 1] != text[text.length() - 1]:
		_l_title.text = text


func _on_window_size_changed() -> void:
	if _l_title.size.x < _width_for_short_title:
		_set_title(SHORT_TITLE)
	else:
		_set_title(LONG_TITLE)


func _set_minimise_corner_radius(radius: int) -> void:
	_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_right = radius
	_b_minimise.get_theme_stylebox(PRESSED).corner_radius_top_right = radius
