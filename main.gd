class_name Main extends Control


@export_category("Window")
@export var min_window_size := Vector2i(128, 128)
@export var max_window_size := Vector2i(512, 512)
@export var move_window_smoothing_factor := .99


func _ready() -> void:
	var window := get_window()
	window.min_size = min_window_size
	window.max_size = max_window_size
