class_name ResizeHandler extends Control


var _resizing: bool
var _distance_to_edge: float
var _mouse_offset: Vector2i
var _window_position: Vector2i
var _window_size: Vector2i

@onready var _window: Window = get_window()


func _ready() -> void:
	gui_input.connect(_on_gui_input)

	_distance_to_edge = _window.size.y - global_position.y


func _process(_delta: float) -> void:
	if not _resizing:
		return
	
	print(int(get_global_mouse_position().y + _distance_to_edge - _mouse_offset.y))
	_window.size.y = int(get_global_mouse_position().y + _distance_to_edge - _mouse_offset.y)
	position.y = _window.size.y - _distance_to_edge


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = not _resizing
		_mouse_offset = get_local_mouse_position()
		_window_position = _window.position
		_window_size = _window.size

