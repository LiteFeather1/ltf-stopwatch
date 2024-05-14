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
			else GLOBAL.window.size.y - global_pos.y
	)


func _input(event: InputEvent) -> void:
	var m_event := event as InputEventMouse
	if not m_event:
		return

	var is_diag := (
		mouse_default_cursor_shape == CURSOR_BDIAGSIZE
		or mouse_default_cursor_shape == CURSOR_FDIAGSIZE
	)
	var mouse_delta := Vector2i(m_event.position) - _mouse_start_pos
	var win := GLOBAL.window
	if mouse_default_cursor_shape == CURSOR_HSIZE or is_diag:
		if global_position.x < win.size.x / 2.0:
			if (
				(win.size.x != win.max_size.x or mouse_delta.x > 0)
				and (win.size.x != win.min_size.x or mouse_delta.x < 0)
			):
				win.position.x += mouse_delta.x - _distance_to_edge.x
				win.size.x = _window_start_size.x + _window_start_pos.x - win.position.x
		else:
			win.size.x = mouse_delta.x + _distance_to_edge.x
	
	if mouse_default_cursor_shape == CURSOR_VSIZE or is_diag:
		if global_position.y < win.size.y / 2.0:
			if (
				(win.size.y != win.max_size.y or mouse_delta.y > 0)
				and (win.size.y != win.min_size.y or mouse_delta.y < 0)
			):
				win.size.y = _window_start_size.y + _window_start_pos.y - win.position.y
				win.position.y += mouse_delta.y - _distance_to_edge.y
		else:
			win.size.y = mouse_delta.y + _distance_to_edge.y


func _gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process_input(not is_processing_input())
		_mouse_start_pos = mb_event.position
		_window_start_pos = GLOBAL.window.position
		_window_start_size = GLOBAL.window.size
