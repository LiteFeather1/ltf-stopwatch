class_name Global extends Node


const FLOAT_MAX := 1.79769e308

const MOVE_WINDOW_PADDING := 4

@onready var tree := get_tree()
@onready var window := get_window()


static func seconds_to_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600.0, fmod(seconds, 3600.0) / 60,fmod(seconds, 60.0)]


func move_window_bottom_left() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		MOVE_WINDOW_PADDING,
		DisplayServer.screen_get_usable_rect(window.current_screen).size.y - window.size.y - MOVE_WINDOW_PADDING
	)


func move_window_bottom_center() -> void:
	var screen_size := DisplayServer.screen_get_usable_rect(window.current_screen).size
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		int((screen_size.x - window.size.x) * .5),
		screen_size.y - window.size.y - MOVE_WINDOW_PADDING
	)


func move_window_bottom_right() -> void:
	window.position = (
		DisplayServer.screen_get_position(window.current_screen)
		+ DisplayServer.screen_get_usable_rect(window.current_screen).size
		- Vector2i(MOVE_WINDOW_PADDING, MOVE_WINDOW_PADDING)
		- window.size
	)