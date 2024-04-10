class_name Main extends Control


@export_category("Window")
@export var _min_window_size := Vector2i(192, 192)
@export var _max_window_size := Vector2i(512, 512)


@export_category("Nodes")
@export var _stopwatch_ui: StopwatchUI
@export var _chrome: ChromeUI

func _ready() -> void:
	var window := get_window()
	window.min_size = _min_window_size
	window.max_size = _max_window_size


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("restore_last_elapsed_time"):
		_stopwatch_ui.restore_last_elapsed_time()
	elif event.is_action_pressed("toggle_pin_window"):
		_chrome.toggle_pin_input()
	elif event.is_action_pressed("minimise_window"):
		_chrome.minimise_window()
