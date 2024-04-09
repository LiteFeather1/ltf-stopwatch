class_name Main extends Control


@export_category("Window")
@export var _min_window_size := Vector2i(192, 192)
@export var _max_window_size := Vector2i(512, 512)


func _ready() -> void:
	var window := get_window()
	window.min_size = _min_window_size
	window.max_size = _max_window_size
