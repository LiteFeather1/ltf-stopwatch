class_name Stopwatch extends VBoxContainer


signal started()
signal paused(time: StringName)
signal resumed(time: StringName)

const CURRENT_TIME_STATE := &"current_time_state"
const LAST_TIME_STATE := &"last_time_state"

@export_multiline var _time_text_template := "[center]%02d:%02d:%02d.[font_size=48]%02d[/font_size][/center]"

@export var _ticking_colour := Color("f7f7f7")
@export var _paused_colour := Color("cecece")

@export var _l_time: RichTextLabel

var _current_time_state: TimeState = TimeState.new()
var _last_time_state: TimeState = TimeState.new()


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process(false)

	await get_tree().physics_frame
	if _current_time_state.elapsed_time > 0.0:
		started.emit()


func _process(delta: float) -> void:
	_current_time_state.elapsed_time += delta
	_set_time()


func has_started() -> bool:
	return _current_time_state.elapsed_time > 0.0


func set_state(state: bool) -> void:
	var current_time := Time.get_datetime_dict_from_system()
	var time := &"%s:%s:%s" % [
		current_time["hour"],
		current_time["minute"],
		current_time["second"]
	]
	if state:
		modulate = _ticking_colour
		
		if not _current_time_state.elapsed_time == 0.0:
			resumed.emit(time)
		else:
			started.emit()
	else:
		modulate = _paused_colour

		paused.emit(time)

	set_process(state)


func reset() -> void:
	_last_time_state = _current_time_state
	_current_time_state.free()
	_current_time_state = TimeState.new()
	_set_time()


func restore_last_elapsed_time() -> void:
	var temp := _current_time_state
	_current_time_state = _last_time_state
	_last_time_state = temp
	_set_time()


func save(save_data: Dictionary) -> void:
	save_data[CURRENT_TIME_STATE] = _current_time_state.as_dict()
	save_data[LAST_TIME_STATE] = _last_time_state.as_dict()


func load(save_data: Dictionary) -> void:
	try_init(_current_time_state, save_data, CURRENT_TIME_STATE)
	try_init(_last_time_state, save_data, LAST_TIME_STATE)

	_set_time()


func get_time_short() -> String:
	return "%02d:%02d:%02d" % [
		_current_time_state.elapsed_time / 3600.0,
		fmod(_current_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_current_time_state.elapsed_time, 60.0)
	]


func _set_time() -> void:
	_l_time.text = _time_text_template % [
		_current_time_state.elapsed_time / 3600.0,
		fmod(_current_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_current_time_state.elapsed_time, 60.0),
		fmod(_current_time_state.elapsed_time, 1) * 100.0
	]


func try_init(time_state: TimeState, dict: Dictionary, key: String) -> void:
	if dict.has(key) and dict[key] is Dictionary:
		time_state.init_from_dict(dict[key])


class TimeState extends Object:
	const ELAPSED_TIME := &"elapsed_time"

	var elapsed_time: float = 0.0

	func init_from_dict(dict: Dictionary) -> void:
		if dict.has(ELAPSED_TIME):
			elapsed_time = dict[ELAPSED_TIME]


	func as_dict() -> Dictionary:
		return {
			ELAPSED_TIME: elapsed_time
		}
