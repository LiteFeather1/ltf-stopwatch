class_name Main
extends Control


@export_category("Window")
@export var min_window_size := Vector2i(128, 128)
@export var max_window_size := Vector2i(512, 512)
@export var move_window_smoothing_factor := .99

@export_category("Buttons")
@export var b_start: Button
@export var b_reset: Button

var dragging_window: bool
var drag_start_pos: Vector2
var smoothed_mouse_pos: Vector2

@onready var window := get_window()


func _ready() -> void:
	window.min_size = min_window_size
	window.max_size = max_window_size

	b_start.toggled.connect(_start_pressed)
	b_reset.pressed.connect(_reset_pressed)


func _process(_delta: float) -> void:
	if dragging_window:
		smoothed_mouse_pos = smoothed_mouse_pos.lerp(window.get_mouse_position(), move_window_smoothing_factor)
		window.position += Vector2i(smoothed_mouse_pos - drag_start_pos)


func _on_hbc_chrome_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == 1: # Left mouse click
		dragging_window = not dragging_window
		var m_pos := window.get_mouse_position()
		drag_start_pos = m_pos
		smoothed_mouse_pos = m_pos


func _close_window() -> void:
	get_tree().quit()


func _minimize_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _stopwatch_started() -> void:
	b_reset.disabled = false


func _start_pressed(state: bool) -> void:
	b_start.text = "P" if state else "C"

func _reset_pressed() -> void:
	b_start.button_pressed = false
	b_start.text = "S"

	b_reset.disabled = true

