class_name Main
extends Control


@export var min_window_size := Vector2i(128, 128)
@export var max_window_size := Vector2i(512, 512)
@export var move_window_smoothing_factor := .99

var dragging_window: bool
var drag_start_pos: Vector2
var smoothed_mouse_pos: Vector2

@onready var window := get_window()


func _ready() -> void:
	DisplayServer.window_set_min_size(min_window_size)
	DisplayServer.window_set_max_size(max_window_size)


func _process(_delta: float) -> void:
	if dragging_window:
		smoothed_mouse_pos = smoothed_mouse_pos.lerp(window.get_mouse_position(), move_window_smoothing_factor)
		window.position += Vector2i(smoothed_mouse_pos - drag_start_pos)


func close_window() -> void:
	get_tree().quit()


func _on_hbc_chrome_gui_input(event: InputEvent) -> void:
	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event and mouse_button_event.button_index == 1: # Left mouse click
		dragging_window = !dragging_window
		var m_pos := window.get_mouse_position()
		drag_start_pos = m_pos
		smoothed_mouse_pos = m_pos
