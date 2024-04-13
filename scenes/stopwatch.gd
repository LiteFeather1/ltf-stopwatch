class_name Stopwatch extends VBoxContainer


signal started()


const ELAPSED_TIME := &"elapsed_time"
const LAST_ELAPSED_TIME := &"last_elapsed_time"

@export_multiline var _time_text_template := "[center]%02d:%02d:%02d.[font_size=48]%02d[/font_size][/center]"

@export var _ticking_colour := Color("f7f7f7")
@export var _paused_colour := Color("cecece")

var _elapsed_time := 0.0
var _last_elapsed_time := 0.0

@onready var _l_time: RichTextLabel = %l_time


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_elapsed_time += delta
	_set_time()


func set_state(state: bool) -> void:
	if _elapsed_time == 0.0 and state:
		started.emit()
	
	set_process(state)
	modulate = _ticking_colour if state else _paused_colour


func reset() -> void:
	_last_elapsed_time = _elapsed_time
	_elapsed_time = 0.0
	_set_time()


func restore_last_elapsed_time() -> void:
	var temp := _elapsed_time
	_elapsed_time = _last_elapsed_time
	_last_elapsed_time = temp
	_set_time()


func save(save_data: Dictionary) -> void:
	save_data[ELAPSED_TIME] = _elapsed_time
	save_data[LAST_ELAPSED_TIME] = _last_elapsed_time


func load(save_data: Dictionary) -> void:
	if save_data.has(ELAPSED_TIME):
		_elapsed_time = save_data[ELAPSED_TIME]
		_set_time()
	
	if save_data.has(LAST_ELAPSED_TIME):
		_last_elapsed_time = save_data[LAST_ELAPSED_TIME]


func get_time_short() -> String:
	return "%02d:%02d:%02d" % [
		_elapsed_time / 3600.0,
		fmod(_elapsed_time, 3600.0) / 60.0,
		fmod(_elapsed_time, 60.0)
	]


func _set_time() -> void:
	_l_time.text = _time_text_template % [
			_elapsed_time / 3600.0,
			fmod(_elapsed_time, 3600.0) / 60.0,
			fmod(_elapsed_time, 60.0),
			fmod(_elapsed_time, 1) * 100.0
	]
