class_name ResizeHandler extends Control


@export var _vertical: bool = true
@export var _left: bool = false

var _resizing: bool
var _distance_to_edge: int
var _mouse_offset: Vector2i
var _window_position: Vector2i
var _window_size: Vector2i

@onready var _window: Window = get_window()


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	if _vertical:
		_distance_to_edge = _window.size.y - int(global_position.y)
	else:
		if _left:
			_distance_to_edge = int(global_position.x)
		else:
			_distance_to_edge = _window.size.x - int(global_position.x)


func _process(_delta: float) -> void:
	if not _resizing:
		return

	var mouse_pos: Vector2i = get_global_mouse_position()
	if _vertical:
		_window.size.y = mouse_pos.y + _distance_to_edge - _mouse_offset.y
		position.y = _window.size.y - _distance_to_edge
	else:
		if _window.size.x == _window.max_size.x:
			pass
		
		if _left:
			_window.position.x += mouse_pos.x - _mouse_offset.x - _distance_to_edge
			_window.size.x = _window_size.x + _window_position.x - _window.position.x
		else:
			_window.size.x = mouse_pos.x + _distance_to_edge - _mouse_offset.x
			# position.x = _window.size.x - _distance_to_edge


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = not _resizing
		_mouse_offset = get_local_mouse_position()
		_window_position = _window.position
		_window_size = _window.size

