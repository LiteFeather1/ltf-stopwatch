class_name Main
extends Control


@export_category("Window")
@export var min_window_size := Vector2i(128, 128)
@export var max_window_size := Vector2i(512, 512)
@export var move_window_smoothing_factor := .99

@export_category("Buttons")
@export var b_start: Button
@export var b_reset: Button


func _ready() -> void:
	var window := get_window()
	window.min_size = min_window_size
	window.max_size = max_window_size

	b_start.toggled.connect(_start_pressed)
	b_reset.pressed.connect(_reset_pressed)


func _stopwatch_started() -> void:
	b_reset.disabled = false


func _start_pressed(state: bool) -> void:
	b_start.text = "P" if state else "C"


func _reset_pressed() -> void:
	b_start.button_pressed = false
	b_start.text = "S"

	b_reset.disabled = true

