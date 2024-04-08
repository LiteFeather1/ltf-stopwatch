class_name Main extends Control


@export_category("Window")
@export var min_window_size := Vector2i(192, 192)
@export var max_window_size := Vector2i(512, 512)


func _ready() -> void:
	var window := get_window()
	window.min_size = min_window_size
	window.max_size = max_window_size
	