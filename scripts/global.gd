class_name Global extends Node


const FLOAT_MAX := 1.79769e308

const MOVE_WINDOW_PADDING := 16

@onready var tree := get_tree()
@onready var window := get_window()


static func seconds_to_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600.0, fmod(seconds, 3600.0) / 60,fmod(seconds, 60.0)]


func move_window_left() -> void:
	var x := window_left_pos()
	if window.position.x == x:
		window.size.x = window.min_size.x
	elif window.size.x == window.min_size.x and window.position.x == window_right_pos():
		var size_diff := window.max_size.x - window.size.x
		window.size.x = window.max_size.x
		window.position.x -= size_diff
	else:
		window.position.x = x


func move_window_right() -> void:
	var x := window_right_pos()
	if window.position.x == x:
		var size_diff := window.size.x - window.min_size.x
		window.size.x = window.min_size.x
		window.position.x += size_diff
	elif window.size.x == window.min_size.x and window.position.x == window_left_pos():
		window.size.x = window.max_size.x
	else:
		window.position.x = x


func move_window_up() -> void:
	window.position.y = window_up_pos()


func move_window_down() -> void:
	window.position.y = window_down_pos()


func move_window_bottom_left() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		MOVE_WINDOW_PADDING,
		DisplayServer.screen_get_usable_rect(window.current_screen).size.y - window.size.y - MOVE_WINDOW_PADDING
	)


func move_window_bottom_centre() -> void:
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


func move_window_centre_left() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		MOVE_WINDOW_PADDING,
		-MOVE_WINDOW_PADDING + int(
			(DisplayServer.screen_get_usable_rect(window.current_screen).size.y - window.size.y) * .5
		)
	)


func move_window_centre() -> void:
	window.position = (
		DisplayServer.screen_get_position(window.current_screen) + Vector2i(
			(DisplayServer.screen_get_usable_rect(window.current_screen).size - window.size) * .5
		)
	)


func move_window_centre_right() -> void:
	var screen_size := DisplayServer.screen_get_usable_rect(window.current_screen).size
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		screen_size.x - window.size.x - MOVE_WINDOW_PADDING,
		int((screen_size.y - window.size.y) * .5)
	)


func move_window_top_left() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		MOVE_WINDOW_PADDING, MOVE_WINDOW_PADDING
	)


func move_window_top_centre() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		int((DisplayServer.screen_get_usable_rect(window.current_screen).size.x - window.size.x) * .5),
		MOVE_WINDOW_PADDING
	)

func move_window_top_right() -> void:
	window.position = DisplayServer.screen_get_position(window.current_screen) + Vector2i(
		DisplayServer.screen_get_usable_rect(window.current_screen).size.x - window.size.x - MOVE_WINDOW_PADDING,
		MOVE_WINDOW_PADDING
	)


func window_left_pos() -> int:
	return DisplayServer.screen_get_position(window.current_screen).x + MOVE_WINDOW_PADDING


func window_right_pos() -> int:
	return (
		DisplayServer.screen_get_position(window.current_screen).x
		+ DisplayServer.screen_get_usable_rect(window.current_screen).size.x
		- window.size.x
		- MOVE_WINDOW_PADDING
	)


func window_up_pos() -> int:
	return DisplayServer.screen_get_position(window.current_screen).y + MOVE_WINDOW_PADDING


func window_down_pos() -> int:
	return (
		DisplayServer.screen_get_position(window.current_screen).y
		+ DisplayServer.screen_get_usable_rect(window.current_screen).size.y
		- window.size.y
		- MOVE_WINDOW_PADDING
	)
