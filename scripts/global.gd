class_name Global extends Node


signal changed_window_size_x()


const NAME := &"Global"

const SAVE_KEYS: PackedStringArray = [
	"_prev_window_size",
	"_prev_window_pos",
]

const FLOAT_MAX := 1.79769e308

const MOVE_WINDOW_PADDING := 16

var _prev_window_size: Vector2i
var _prev_window_pos: Vector2i

@onready var tree := get_tree()
@onready var window := get_window()


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


static func seconds_to_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600.0, fmod(seconds, 3600.0) / 60,fmod(seconds, 60.0)]


func move_window_left() -> void:
	var left := _window_left_pos()
	if window.always_on_top:
		window.position.x = left
	elif window.position.x == left:
		_prev_window_size.x = window.size.x
		window.size.x = window.min_size.x
		changed_window_size_x.emit()
	elif window.position.x == _window_right_pos():
		if window.size.x == window.min_size.x:
			window.size.x = _prev_window_size.x
			window.position.x -= _prev_window_size.x - window.min_size.x
			changed_window_size_x.emit()
		else:
			window.position.x = _prev_window_pos.x
	else:
		_prev_window_pos.x = window.position.x
		window.position.x = left


func move_window_right() -> void:
	var right := _window_right_pos()
	if window.always_on_top:
		window.position.x = right
	elif window.position.x == right:
		_prev_window_size.x = window.size.x
		window.size.x = window.min_size.x
		window.position.x += _prev_window_size.x - window.min_size.x
		changed_window_size_x.emit()
	elif window.position.x == _window_left_pos():
		if window.size.x == window.min_size.x:
			window.size.x = _prev_window_size.x
			changed_window_size_x.emit()
		else:
			window.position.x = _prev_window_pos.x
	else:
		_prev_window_pos.x = window.position.x
		window.position.x = right


func move_window_up() -> void:
	var up := _window_up_pos()
	if window.always_on_top:
		window.position.y = up
	elif window.position.y == up:
		_prev_window_size.y = window.size.y
		window.size.y = window.min_size.y
	elif window.position.y == _window_down_pos():
		if window.size.y == window.min_size.y:
			window.size.y = _prev_window_size.y
			window.position.y -= _prev_window_size.y - window.min_size.y
		else:
			window.position.y = _prev_window_pos.y
	else:
		_prev_window_pos.y = window.position.y
		window.position.y = up


func move_window_down() -> void:
	var down := _window_down_pos()
	if window.always_on_top:
		window.position.y = down
	elif window.position.y == down:
		_prev_window_size.y = window.size.y
		window.size.y = window.min_size.y
		window.position.y += _prev_window_size.y - window.min_size.y
	elif window.position.y == _window_up_pos():
		if window.size.y == window.min_size.y:
			window.size.y = _prev_window_size.y
		else:
			window.position.y = _prev_window_pos.y
	else:
		_prev_window_pos.y = window.position.y
		window.position.y = down


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


func _window_left_pos() -> int:
	return DisplayServer.screen_get_position(window.current_screen).x + MOVE_WINDOW_PADDING


func _window_right_pos() -> int:
	return (
		DisplayServer.screen_get_position(window.current_screen).x
		+ DisplayServer.screen_get_usable_rect(window.current_screen).size.x
		- window.size.x
		- MOVE_WINDOW_PADDING
	)


func _window_up_pos() -> int:
	return DisplayServer.screen_get_position(window.current_screen).y + MOVE_WINDOW_PADDING


func _window_down_pos() -> int:
	return (
		DisplayServer.screen_get_position(window.current_screen).y
		+ DisplayServer.screen_get_usable_rect(window.current_screen).size.y
		- window.size.y
		- MOVE_WINDOW_PADDING
	)


func load(save_dict: Dictionary) -> void:
	for key: String in SAVE_KEYS:
		self[key] = str_to_var(save_dict[key])


func save() -> Dictionary:
	var save_dict := {}
	for key: String in SAVE_KEYS:
		save_dict[key] = var_to_str(self[key])

	return save_dict
