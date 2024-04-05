class_name Main
extends Control


@export var min_window_size := Vector2i(128, 128)
@export var max_window_size := Vector2i(512, 512)


func _ready() -> void:
	DisplayServer.window_set_min_size(min_window_size)
	DisplayServer.window_set_max_size(max_window_size)
