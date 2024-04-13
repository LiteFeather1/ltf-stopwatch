class_name Main extends Panel


const SAVE_PATH := &"user://ltf_stopwatch.json"
const SAVEABLE := &"user://ltf_stopwatch.json"

@export_category("Window")
@export var _min_window_size := Vector2i(192, 192)
@export var _max_window_size := Vector2i(512, 512)


@export_category("Nodes")
@export var _stopwatch_ui: StopwatchUI
@export var _chrome: ChromeUI


func _ready() -> void:
	_chrome.close_pressed.connect(_quit_app)

	var window := get_window()
	window.min_size = _min_window_size
	window.max_size = _max_window_size

	var tree := get_tree()
	window.focus_entered.connect(func() -> void:
		tree.paused = false
	)
	window.focus_exited.connect(func() -> void:
		tree.paused = true
	)

	if not FileAccess.file_exists(SAVE_PATH):
		print("Couldn't load %s" % SAVE_PATH)
		return
	
	var json = JSON.parse_string(FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text())
	if json == null:
		print("json object is null")
		return
	
	var save_data: Dictionary = json
	
	for saveable in tree.get_nodes_in_group(SAVEABLE):
		saveable.load(save_data)

	if save_data.has("version"):
		print("Loaded %s version: %s" % [SAVE_PATH, save_data["version"]])


func _shortcut_input(event: InputEvent) -> void:
	# Stopwatch UI Events
	if event.is_action_pressed("toggle_stopwatch"):
		_stopwatch_ui.toggle_stopwatch()
	elif event.is_action_pressed("reset_stopwatch"):
		_stopwatch_ui.try_reset_stopwatch()
	elif event.is_action_pressed("copy_to_clipboard"):
		_stopwatch_ui.try_copy_to_clipboard()
	elif event.is_action_pressed("restore_last_elapsed_time"):
		_stopwatch_ui.restore_last_elapsed_time()
	# Window Events
	elif event.is_action_pressed("toggle_pin_window"):
		_chrome.toggle_pin_input()
	elif event.is_action_pressed("minimise_window"):
		_chrome.minimise_window()


func _quit_app() -> void:
	var save_data := {
		"version": ProjectSettings.get_setting("application/config/version"),
	}

	var tree := get_tree()
	for saveable in tree.get_nodes_in_group(SAVEABLE):
		saveable.save(save_data)

	FileAccess.open(SAVE_PATH, FileAccess.WRITE)\
			.store_string(JSON.stringify(save_data))

	tree.quit()
