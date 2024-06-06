class_name Main extends Panel


const SAVE_PATH := &"user://ltf_stopwatch.json"
const PASS := &"744967c4-6e81-4947-a1f4-06626abc615b"

const VERSION := &"version"
const SAVEABLE := &"saveable"

@export_category("Window")
@export var _min_window_size: Vector2i = Vector2i(192, 192)
@export var _max_window_size: Vector2i = Vector2i(512, 512)

@export_category("Colours")
@export var _pinned_colour: Color = Color("#181818")

@export_category("Nodes")
@export var _stopwatch_ui: StopwatchUI
@export var _title_bar_ui: TitleBarUI

var _normal_colour: Color


func _ready() -> void:
	_title_bar_ui.pin_toggled.connect(_on_title_bar_ui_pin_toggled)
	_title_bar_ui.close_pressed.connect(_quit_app)
	_title_bar_ui.last_stopwatch_pressed.connect(_stopwatch_ui.restore_last_time_state)
	
	GLOBAL.window.close_requested.connect(_quit_app)
	GLOBAL.window.focus_entered.connect(func() -> void:
		GLOBAL.tree.paused = false
	)
	GLOBAL.window.focus_exited.connect(func() -> void:
		GLOBAL.tree.paused = true
	)

	GLOBAL.window.min_size = _min_window_size
	GLOBAL.window.max_size = _max_window_size

	_normal_colour = get_theme_stylebox("panel").bg_color

	if not FileAccess.file_exists(SAVE_PATH):
		print("No file at %s" % SAVE_PATH)
		return

	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, PASS)
	if file == null:
		print("Couldn't load %s. Error %s" % [SAVE_PATH, FileAccess.get_open_error()])
		return

	var save_data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	if VERSION in save_data:
		if save_data[VERSION] == ProjectSettings.get_setting("application/config/version"):
			print("Loaded %s version: %s" % [SAVE_PATH, save_data[VERSION]])
		else:
			print("Tried to load old version of save")
			return

	for saveable in GLOBAL.tree.get_nodes_in_group(SAVEABLE):
		saveable.load(save_data[saveable.NAME])


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("restore_last_time_state"):
		_stopwatch_ui.restore_last_time_state()
	elif event.is_action_pressed("redo_deleted_pause_entry"):
		_stopwatch_ui.redo_deleted_stopwatch_entry_ui()
	elif event.is_action_pressed("undo_deleted_pause_entry"):
		_stopwatch_ui.undo_deleted_stopwatch_entry_ui()


func _on_title_bar_ui_pin_toggled(pinning: bool) -> void:
	get_theme_stylebox("panel").bg_color = _pinned_colour if pinning else _normal_colour
	_stopwatch_ui.fix_stopwatch_tray_positioning()


func _quit_app() -> void:
	_stopwatch_ui.pause_stopwatch_if_running()
	
	var save_data := {}
	save_data[VERSION] = ProjectSettings.get_setting("application/config/version")

	for saveable in GLOBAL.tree.get_nodes_in_group(SAVEABLE):
		save_data[saveable.NAME] = saveable.save()
	
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, PASS)
	file.store_string(JSON.stringify(save_data, "", false))
	file.close()

	GLOBAL.tree.quit()
