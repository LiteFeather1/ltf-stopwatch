class_name Main extends Panel


const SAVE_PATH := &"user://ltf_stopwatch.json"
const PASS := &"6ab067d7-104a-401d-a428-3cbb01354ece"

const VERSION := &"version"
const SAVEABLE := &"saveable"

@export_category("Window")
@export var _min_window_size: Vector2i = Vector2i(192, 128)
@export var _max_window_size: Vector2i = Vector2i(512, 512)

@export_category("Colours")
@export var _pinned_colour: Color = Color("#181818")

@export_category("Nodes")
@export var _stopwatch_ui: StopwatchUI
@export var _title_bar_ui: TitleBarUI

var _normal_colour: Color

var _windows_key_pressed: bool = false


func _ready() -> void:
	_title_bar_ui.pin_toggled.connect(_on_title_bar_ui_pin_toggled)
	_title_bar_ui.close_pressed.connect(_quit_app)
	_title_bar_ui.last_stopwatch_pressed.connect(_stopwatch_ui.restore_last_time_state)

	GLOBAL.changed_window_size_x.connect(_title_bar_ui.delay_window_size_changed)

	GLOBAL.window.close_requested.connect(_quit_app)
	GLOBAL.window.focus_entered.connect(func() -> void:
		GLOBAL.tree.paused = false
	)
	GLOBAL.window.focus_exited.connect(func() -> void:
		GLOBAL.tree.paused = true
		_windows_key_pressed = false
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
	elif event.is_action_pressed("paste_in_time"):
		_stopwatch_ui.paste_in_time()
	elif event.is_action_pressed("open_title_bar_popup_menu"):
		_title_bar_ui.show_popup_menu_shortcut()
	elif event.is_action_pressed("increment_time_by_one"):
		_stopwatch_ui.get_stopwatch().modify_time(1)
	elif event.is_action_pressed("decrement_time_by_one"):
		var stopwatch := _stopwatch_ui.get_stopwatch()
		stopwatch.modify_time(-minf(1, stopwatch.get_time_state().elapsed_time))
	elif event.is_action_pressed("increment_time_by_five"):
		_stopwatch_ui.get_stopwatch().modify_time(5)
	elif event.is_action_pressed("decrement_time_by_five"):
		var stopwatch = _stopwatch_ui.get_stopwatch()
		stopwatch.modify_time(-minf(5, stopwatch.get_time_state().elapsed_time))
	else:
		var event_key := event as InputEventKey
		if not event_key:
			return

		if _windows_key_pressed:
			if event.is_action_released("windows_key"):
				_windows_key_pressed = false
				return

			if event_key.shift_pressed:
				return

			# I have no idea why this only works with key released, maybe Windows is just eating the inputs
			match event_key.keycode:
				KEY_LEFT:
					GLOBAL.move_window_left()
				KEY_RIGHT:
					GLOBAL.move_window_right()
				KEY_UP:
					GLOBAL.move_window_up()
				KEY_DOWN:
					GLOBAL.move_window_down()

			return
		elif event.is_echo() or event.is_released():
			return

		_windows_key_pressed = event.is_action_pressed("windows_key")

		if Input.is_key_pressed(KEY_DELETE):
			for i in 11:
				if (
					(event_key.keycode == KEY_0 + i or event_key.keycode == KEY_KP_0 + i)
					and i <= _stopwatch_ui.get_stopwatch_tray_entries_ui_size()
				):
					_stopwatch_ui.delete_stopwatch_entry_ui((i + 9) % 10)
					break
		elif event_key.ctrl_pressed:
			match event_key.keycode:
				KEY_LEFT:
					GLOBAL.move_window_left()
				KEY_RIGHT:
					GLOBAL.move_window_right()
				KEY_UP:
					GLOBAL.move_window_up()
				KEY_DOWN:
					GLOBAL.move_window_down()
				KEY_KP_1:
					GLOBAL.move_window_bottom_left()
				KEY_KP_2:
					GLOBAL.move_window_bottom_centre()
				KEY_KP_3:
					GLOBAL.move_window_bottom_right()
				KEY_KP_4:
					GLOBAL.move_window_centre_left()
				KEY_KP_5:
					GLOBAL.move_window_centre()
				KEY_KP_6:
					GLOBAL.move_window_centre_right()
				KEY_KP_7:
					GLOBAL.move_window_top_left()
				KEY_KP_8:
					GLOBAL.move_window_top_centre()
				KEY_KP_9:
					GLOBAL.move_window_top_right()
		elif event_key.alt_pressed:
			match event_key.keycode:
				KEY_1:
					GLOBAL.move_window_bottom_left()
				KEY_2:
					GLOBAL.move_window_bottom_centre()
				KEY_3:
					GLOBAL.move_window_bottom_right()
				KEY_4:
					GLOBAL.move_window_centre_left()
				KEY_5:
					GLOBAL.move_window_centre()
				KEY_6:
					GLOBAL.move_window_centre_right()
				KEY_7:
					GLOBAL.move_window_top_left()
				KEY_8:
					GLOBAL.move_window_top_centre()
				KEY_9:
					GLOBAL.move_window_top_right()


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
