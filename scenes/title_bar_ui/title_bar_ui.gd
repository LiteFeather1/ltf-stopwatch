class_name TitleBarUI extends Panel


signal pin_toggled(state: bool)
signal close_pressed()

signal last_stopwatch_pressed()
signal low_process_pressed()


enum {
	POPUP_INDEX_PIN = 0,
	POPUP_INDEX_MINIMISE = 1,
	POPUP_INDEX_MAX_SIZE = 2,
	POPUP_INDEX_MIN_SIZE = 3,
	POPUP_INDEX_LAST_STOPWATCH = 5,
	POPUP_INDEX_LOW_PROCESS = 7,
	POPUP_INDEX_CLOSE = 9,
}


const NAME := &"TitleBarUI"

const SAVE_KEYS: PackedStringArray = [
	"_window_position",
	"_window_size",
	"_window_pinned_position",
	"_window_pinned_size",
]

const IS_LOW_PROCESSOR := &"is_low_processor"

const PIN := &"pin"
const UNPIN := &"unpin"

const HOVER := &"hover"
const PRESSED := &"pressed"

@export var _window_margin_when_pinning := Vector2i(-32, 32)

@export_category("Title")
@export var _l_title: Label
@export var _tr_icon: TextureRect
@export var _mid_title_length: int = 8
@export var _short_title_length: int = 5

@export_category("Buttons")
@export var _b_close: Button
@export var _b_minimise: Button

@export_category("Button Pin")
@export var _b_pin: ButtonHoverTip
@export var _sprite_pin: Texture2D
@export var _sprite_unpin: Texture2D

@export_category("Popup Menu")
@export var _popup_menu: PopupMenu
@export var _popup_menu_shortcuts: Dictionary
@export var _sprite_checked: Texture2D
@export var _sprite_unchecked: Texture2D

var _long_title_length: float
var _width_for_mid_title: float
var _width_for_short_title: float

var _start_drag_pos: Vector2
var _window_position: Vector2i = Vector2i(-1, -1)
var _window_size: Vector2i
var _window_pinned_position: Vector2i
var _window_pinned_size: Vector2i

var _is_mouse_in: bool = false


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process_input(false)

	_tr_icon.gui_input.connect(_on_icon_gui_input)

	_b_close.pressed.connect(_close_window)
	_b_pin.toggled.connect(_on_button_pin_toggled)
	_b_minimise.pressed.connect(_minimise_window)

	GLOBAL.window.size_changed.connect(_on_window_size_changed)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_b_minimise.add_theme_stylebox_override(
		HOVER, _b_minimise.get_theme_stylebox(HOVER).duplicate()
	)
	_b_minimise.add_theme_stylebox_override(
		PRESSED, _b_minimise.get_theme_stylebox(PRESSED).duplicate()
	)

	_long_title_length = _l_title.text.length()

	var font := _l_title.get_theme_font("font")
	var font_size := _l_title.get_theme_font_size("font_size")

	_width_for_mid_title = font.get_string_size(
		_l_title.text, _l_title.horizontal_alignment, -1, font_size,
	).x + 2.0

	_width_for_short_title = font.get_string_size(
		_l_title.text.substr(0, _mid_title_length), _l_title.horizontal_alignment, -1, font_size
	).x + 2.0

	_popup_menu.index_pressed.connect(_on_popup_menu_index_pressed)
	_popup_menu.transient = false

	var shortcut := Shortcut.new()
	shortcut.events = InputMap.action_get_events("restore_last_time_state")
	_popup_menu.set_item_shortcut(POPUP_INDEX_LAST_STOPWATCH, shortcut)
	for key in _popup_menu_shortcuts:
		_popup_menu.set_item_shortcut(key, _popup_menu_shortcuts[key])

	await GLOBAL.tree.process_frame

	if _window_position.x != -1:
		var screens_area := Vector2i.ZERO
		for i in DisplayServer.get_screen_count():
			screens_area += DisplayServer.screen_get_size(i)

		if _window_position.x >= screens_area.x:
			_window_position.x = GLOBAL.window.position.x

		if _window_position.y >= screens_area.y:
			_window_position.y = GLOBAL.window.position.y

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
	var m_event := event as InputEventMouseMotion
	if m_event:
		GLOBAL.window.position += Vector2i(m_event.position - _start_drag_pos)


func _gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if not mb_event:
		return

	if mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process_input(mb_event.is_pressed())
		_start_drag_pos = mb_event.position

		if (
			_is_mouse_in
			and mb_event.is_released()
			and (mb_event.alt_pressed or mb_event.is_command_or_control_pressed())
		):
			_toggle_pin_window()
		elif mb_event.double_click:
			if GLOBAL.window.size != GLOBAL.window.max_size:
				_set_window_max_size()
			else:
				_set_window_min_size()
	elif _is_mouse_in and mb_event.is_released():
		if mb_event.button_index == MOUSE_BUTTON_MIDDLE:
			_minimise_window()
		elif mb_event.button_index == MOUSE_BUTTON_RIGHT:
			_popup_menu.position = GLOBAL.window.position + Vector2i(mb_event.position)
			_show_popup_menu()


func show_popup_menu_shortcut() -> void:
	_popup_menu.position = GLOBAL.window.position + Vector2i(0, int(size.y))
	_show_popup_menu()


# We await a small delay cuz the ui sizes takes time to update
func delay_window_size_changed() -> void:
	await GLOBAL.tree.create_timer(.000001).timeout
	_on_window_size_changed()


func load(save_dict: Dictionary) -> void:
	for key: String in SAVE_KEYS:
		self[key] = str_to_var(save_dict[key])
	
	if not save_dict[IS_LOW_PROCESSOR]:
		OS.low_processor_usage_mode = false
		Engine.max_fps = 0
		_popup_menu.set_item_icon(POPUP_INDEX_LOW_PROCESS, _sprite_unchecked)
	else:
		Engine.max_fps = int(DisplayServer.screen_get_refresh_rate(GLOBAL.window.current_screen)) -1


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

	save_dict[IS_LOW_PROCESSOR] = OS.low_processor_usage_mode
	return save_dict


func _on_icon_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if (
		not mb_event
		or mb_event.is_pressed()
		or not _tr_icon.get_rect().has_point(mb_event.position)
	):
		return

	if mb_event.button_index == MOUSE_BUTTON_LEFT:
		_popup_menu.position = GLOBAL.window.position + Vector2i(
			int(_tr_icon.size.x * .5), int(size.y)
		)
		_show_popup_menu()
	elif mb_event.button_index == MOUSE_BUTTON_RIGHT:
		_popup_menu.position = GLOBAL.window.position + Vector2i(mb_event.position)
		_show_popup_menu()


func _close_window() -> void:
	close_pressed.emit()


func _on_button_pin_toggled(pinning: bool) -> void:
	_b_close.visible = not pinning
	GLOBAL.window.always_on_top = pinning

	if pinning:
		_b_pin.icon = _sprite_unpin
		_b_pin.set_tip_name(UNPIN)

		_set_minimise_corner_radius(_b_close.get_theme_stylebox(HOVER).corner_radius_top_right)

		_window_position = GLOBAL.window.position
		_window_size = GLOBAL.window.size

		GLOBAL.window.position = _window_pinned_position
		GLOBAL.window.size = _window_pinned_size
	else:
		_b_pin.icon = _sprite_pin
		_b_pin.set_tip_name(PIN)

		_set_minimise_corner_radius(_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_left)

		_window_pinned_position = GLOBAL.window.position
		_window_pinned_size = GLOBAL.window.size
		
		GLOBAL.window.position = _window_position
		GLOBAL.window.size = _window_size

	pin_toggled.emit(pinning)

	delay_window_size_changed()


func _minimise_window() -> void:
	GLOBAL.window.mode = Window.MODE_MINIMIZED


func _on_window_size_changed() -> void:
	if _l_title.size.x < _width_for_short_title:
		_l_title.visible_ratio = _short_title_length / _long_title_length
	elif _l_title.size.x < _width_for_mid_title:
		_l_title.visible_ratio = _mid_title_length / _long_title_length
	else:
		_l_title.visible_ratio = 1.0


func _on_mouse_entered() -> void:
	_is_mouse_in = true


func _on_mouse_exited() -> void:
	_is_mouse_in = false


func _on_popup_menu_index_pressed(index: int) -> void:
	match index:
		POPUP_INDEX_PIN:
			_toggle_pin_window()
		POPUP_INDEX_MINIMISE:
			_minimise_window()
		POPUP_INDEX_MAX_SIZE:
			_set_window_max_size()
		POPUP_INDEX_MIN_SIZE:
			_set_window_min_size()
		POPUP_INDEX_MAX_SIZE:
			last_stopwatch_pressed.emit()
		POPUP_INDEX_LOW_PROCESS:
			OS.low_processor_usage_mode = not OS.low_processor_usage_mode
			if OS.low_processor_usage_mode:
				Engine.max_fps = int(DisplayServer.screen_get_refresh_rate(
					GLOBAL.window.current_screen
				)) -1
				_popup_menu.set_item_icon(POPUP_INDEX_LOW_PROCESS, _sprite_checked)
			else:
				Engine.max_fps = 0
				_popup_menu.set_item_icon(POPUP_INDEX_LOW_PROCESS, _sprite_unchecked)
		POPUP_INDEX_CLOSE:
			_close_window()
		_:
			assert(false, "Invalid titlebar popup menu index")


func _set_minimise_corner_radius(radius: int) -> void:
	_b_minimise.get_theme_stylebox(HOVER).corner_radius_top_right = radius
	_b_minimise.get_theme_stylebox(PRESSED).corner_radius_top_right = radius


func _show_popup_menu() -> void:
	if _b_pin.button_pressed:
		_popup_menu.set_item_text(POPUP_INDEX_PIN, UNPIN)
		_popup_menu.set_item_icon(POPUP_INDEX_PIN, _sprite_unpin)
	else:
		_popup_menu.set_item_text(POPUP_INDEX_PIN, PIN)
		_popup_menu.set_item_icon(POPUP_INDEX_PIN, _sprite_pin)

	_popup_menu.set_item_disabled(
		POPUP_INDEX_MAX_SIZE, GLOBAL.window.size == GLOBAL.window.max_size
	)

	_popup_menu.set_item_disabled(
		POPUP_INDEX_MIN_SIZE, GLOBAL.window.size == GLOBAL.window.min_size
	)

	_popup_menu.show()


func _toggle_pin_window() -> void:
	_b_pin.button_pressed = not _b_pin.button_pressed


func _set_window_max_size() -> void:
	GLOBAL.window.size = GLOBAL.window.max_size
	delay_window_size_changed()


func _set_window_min_size() -> void:
	GLOBAL.window.size = GLOBAL.window.min_size
	delay_window_size_changed()
