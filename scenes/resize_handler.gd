class_name ResizeHandler extends Control


var _distance_to_edge: Vector2i

var _mouse_start_pos: Vector2
var _window_start_pos: Vector2i
var _window_start_size: Vector2i

@onready var _window: Window = get_window()


func _ready() -> void:
	set_process(false)

	gui_input.connect(_on_gui_input)

	_distance_to_edge = Vector2i(
		int(global_position.x) if global_position.x < _window.size.x / 2.0
			else _window.size.x - int(global_position.x),
		int(global_position.y) if (global_position.y < _window.size.y / 2.0)
			else _window.size.y - int(global_position.y)
	)


func _process(_delta: float) -> void:
	var is_diag := mouse_default_cursor_shape == CURSOR_BDIAGSIZE or mouse_default_cursor_shape == CURSOR_FDIAGSIZE
	var mouse_delta: Vector2i = get_global_mouse_position() - _mouse_start_pos
	if mouse_default_cursor_shape == CURSOR_HSIZE or is_diag:
		if global_position.x < _window.size.x / 2.0:
			if (_window.size.x != _window.max_size.x or mouse_delta.x > 0)\
					and (_window.size.x != _window.min_size.x or mouse_delta.x < 0):
				_window.position.x += mouse_delta.x - _distance_to_edge.x
				_window.size.x = _window_start_size.x + _window_start_pos.x - _window.position.x
		else:
			_window.size.x = mouse_delta.x + _distance_to_edge.x
	
	if mouse_default_cursor_shape == CURSOR_VSIZE or is_diag:
		if global_position.y < _window.size.y / 2.0:
			if (_window.size.y != _window.max_size.y or mouse_delta.y > 0)\
					and (_window.size.y != _window.min_size.y or mouse_delta.y < 0):
				_window.position.y += mouse_delta.y - _distance_to_edge.y
				_window.size.y = _window_start_size.y + _window_start_pos.y - _window.position.y
		else:
			_window.size.y = mouse_delta.y + _distance_to_edge.y



func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		set_process(not is_processing())
		_mouse_start_pos = get_local_mouse_position()
		_window_start_pos = _window.position
		_window_start_size = _window.size
