class_name ResizeHandler extends Control


var _distance_to_edge: Vector2i

static var _mouse_start_pos: Vector2i
static var _window_start_pos: Vector2i
static var _window_start_size: Vector2i


func _ready() -> void:
	set_process_input(false)

	var global_pos := Vector2i(global_position)
	_distance_to_edge = Vector2i(
		global_pos.x if global_position.x < GLOBAL.window.size.x * .5
			else GLOBAL.window.size.x - global_pos.x,
		global_pos.y if (global_position.y < GLOBAL.window.size.y * .5)
			else GLOBAL.window.size.y - global_pos.y,
	)


func _input(event: InputEvent) -> void:
	var m_event := event as InputEventMouse
	if not m_event:
		return

	var mouse_delta := Vector2i(m_event.position) - _mouse_start_pos
	if (
		mouse_default_cursor_shape == CURSOR_BDIAGSIZE
		or mouse_default_cursor_shape == CURSOR_FDIAGSIZE
	):
		_horizontal_resize(mouse_delta.x)
		_vertical_resize(mouse_delta.y)
	elif mouse_default_cursor_shape == CURSOR_HSIZE:
		_horizontal_resize(mouse_delta.x)
	elif mouse_default_cursor_shape == CURSOR_VSIZE:
		_vertical_resize(mouse_delta.y)


func _gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_start_pos = mb_event.position
		_window_start_pos = GLOBAL.window.position
		_window_start_size = GLOBAL.window.size
		set_process_input(not is_processing_input())


func _horizontal_resize(x_delta: int) -> void:
	var win := GLOBAL.window
	
	if global_position.x < win.size.x * .5:
		if (
			(win.size.x != win.max_size.x or x_delta > 0)
			and (win.size.x != win.min_size.x or x_delta < 0)
		):
			win.position.x += x_delta - _distance_to_edge.x
			win.size.x = _window_start_size.x + _window_start_pos.x - win.position.x
	else:
		win.size.x = x_delta + _distance_to_edge.x


func _vertical_resize(y_delta: int) -> void:
	var win := GLOBAL.window
	if global_position.y < win.size.y * .5:
		if (
			(win.size.y != win.max_size.y or y_delta > 0)
			and (win.size.y != win.min_size.y or y_delta < 0)
		):
			win.position.y += y_delta - _distance_to_edge.y
			win.size.y = _window_start_pos.y + _window_start_size.y - win.position.y
	else:
		win.size.y = y_delta + _distance_to_edge.y