class_name Main extends Panel


const SAVE_PATH := &"user://ltf_stopwatch.json"
const VERSION := &"version"
const SAVEABLE := &"saveable"

@export_category("Window")
@export var _min_window_size := Vector2i(192, 192)
@export var _max_window_size := Vector2i(512, 512)


@export_category("Nodes")
@export var _stopwatch_ui: StopwatchUI
@export var _title_bar_ui: TitleBarUI


func _ready() -> void:
	_title_bar_ui.close_pressed.connect(_quit_app)
	
	Global.window.min_size = _min_window_size
	Global.window.max_size = _max_window_size

	Global.window.focus_entered.connect(func() -> void:
		Global.tree.paused = false
	)
	Global.window.focus_exited.connect(func() -> void:
		Global.tree.paused = true
	)

	if not FileAccess.file_exists(SAVE_PATH):
		print("Couldn't load %s" % SAVE_PATH)
		return
	
	var json = JSON.parse_string(FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text())
	if not json is Dictionary:
		print("Json object is not a dictionary")
		return
	
	var save_data: Dictionary = json
	
	for saveable in Global.tree.get_nodes_in_group(SAVEABLE):
		saveable.load(save_data)

	if save_data.has(VERSION):
		print("Loaded %s version: %s" % [SAVE_PATH, save_data[VERSION]])


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("restore_last_time_state"):
		_stopwatch_ui.restore_last_time_state()
	elif event.is_action_pressed("redo_deleted_pause_entry"):
		_stopwatch_ui.redo_deleted_pause_entry()
	elif event.is_action_pressed("undo_deleted_pause_entry"):
		_stopwatch_ui.undo_deleted_pause_entry()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_app()


func _quit_app() -> void:
	_stopwatch_ui.pause_stopwatch_if_running()
	
	var save_data := {}
	save_data[VERSION] = ProjectSettings.get_setting("application/config/version")

	for saveable in Global.tree.get_nodes_in_group(SAVEABLE):
		saveable.save(save_data)

	FileAccess.open(SAVE_PATH, FileAccess.WRITE)\
			.store_string(JSON.stringify(save_data, "\t", false))

	Global.tree.quit()
