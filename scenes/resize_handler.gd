class_name ResizeHandler extends Control


var _move_window: bool = false

var _resizing: bool
var _distance_to_edge: int
var _mouse_offset: Vector2i
var _window_position: Vector2i
var _window_size: Vector2i

@onready var _window: Window = get_window()


func _ready() -> void:
	gui_input.connect(_on_gui_input)

	# Check if it's vertical
	if mouse_default_cursor_shape == CURSOR_VSIZE:
		_move_window = global_position.y < _window.size.y / 2.0
		if _move_window:
			_distance_to_edge = int(global_position.y)
		else:
			_distance_to_edge = _window.size.y - int(global_position.y)
	else:
		_move_window = global_position.x < _window.size.x / 2.0
		if _move_window:
			_distance_to_edge = int(global_position.x)
		else:
			_distance_to_edge = _window.size.x - int(global_position.x)


func _process(_delta: float) -> void:
	if not _resizing:
		return

	var mouse_pos: Vector2i = get_global_mouse_position()
	# Check if it's vertical
	if mouse_default_cursor_shape == CURSOR_VSIZE:
		if _move_window:
			var delta := mouse_pos.y - _mouse_offset.y - _distance_to_edge
			if (_window.size.y == _window.max_size.y and delta <= 0.0)\
					or (_window.size.y == _window.min_size.y and delta >= 0.0):
				return
			
			_window.position.y += delta
			_window.size.y = _window_size.y + _window_position.y - _window.position.y
		else:
			_window.size.y = mouse_pos.y + _distance_to_edge - _mouse_offset.y
	else:
		if _move_window:
			var delta := mouse_pos.x - _mouse_offset.x - _distance_to_edge
			if (_window.size.x == _window.max_size.x and delta <= 0.0)\
					or (_window.size.x == _window.min_size.x and delta >= 0.0):
				return
			
			_window.position.x += delta
			_window.size.x = _window_size.x + _window_position.x - _window.position.x
		else:
			_window.size.x = mouse_pos.x + _distance_to_edge - _mouse_offset.x


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = not _resizing
		_mouse_offset = get_local_mouse_position()
		_window_position = _window.position
		_window_size = _window.size

