class_name Main extends Panel


const SAVE_PATH := &"user://ltf_stopwatch.json"
const PASS := &"744967c4-6e81-4947-a1f4-06626abc615b"
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
		print("No file at %s" % SAVE_PATH)
		return
	
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, PASS)
	if file == null:
		print("Couldn't load %s. Error %s" % [SAVE_PATH, FileAccess.get_open_error()])
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if not json is Dictionary:
		print("Json object is not a dictionary")
		return
	
	var save_data: Dictionary = json
	
	for saveable in Global.tree.get_nodes_in_group(SAVEABLE):
		saveable.load(save_data)

	if save_data.has(VERSION):
		print("Loaded %s version: %s" % [SAVE_PATH, save_data[VERSION]])


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("restore_last_elapsed_time"):
		_stopwatch_ui.restore_last_elapsed_time()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_app()


func _quit_app() -> void:
	var save_data := {}
	save_data[VERSION] = ProjectSettings.get_setting("application/config/version")

	for saveable in Global.tree.get_nodes_in_group(SAVEABLE):
		saveable.save(save_data)
	
	var file := FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, PASS)
	file.store_string(JSON.stringify(save_data, "", false))
	file.close()

	Global.tree.quit()
