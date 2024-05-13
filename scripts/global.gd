class_name Global extends Node


const FLOAT_MAX := 1.79769e308

@onready var tree := get_tree()
@onready var window := get_window()


static func seconds_to_time(seconds: float) -> String:
	return "%02d:%02d:%02d" % [
		seconds / 3600.0,
		fmod(seconds, 3600.0) / 60,
		fmod(seconds, 60.0),
	]
