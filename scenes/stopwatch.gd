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
	
	var seconds := \
		float(current_time["hour"]) * 3600.0\
		+ float(current_time["minute"]) * 60.0\
		+ float(current_time["second"])

	if state:
		modulate = _ticking_colour
		
		if not _current_time_state.elapsed_time == 0.0:
			resumed.emit(time)
			_current_time_state.resumed_times.append(seconds)
		else:
			started.emit()
	else:
		modulate = _paused_colour

		paused.emit(time)
		_current_time_state.paused_times.append(seconds)

	set_process(state)


func reset() -> void:
	_last_time_state.free()
	_last_time_state = _current_time_state
	_current_time_state = TimeState.new()
	_set_time()


func restore_last_elapsed_time() -> void:
	var temp := _current_time_state
	_current_time_state = _last_time_state
	_last_time_state = temp
	_set_time()


func get_time_short() -> String:
	return "%02d:%02d:%02d" % [
		_current_time_state.elapsed_time / 3600.0,
		fmod(_current_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_current_time_state.elapsed_time, 60.0)
	]


func get_current_paused_times() -> Array[float]:
	return _current_time_state.paused_times


func get_current_resumed_times() -> Array[float]:
	return _current_time_state.resumed_times


func save(save_data: Dictionary) -> void:
	save_data[CURRENT_TIME_STATE] = _current_time_state.as_dict()
	save_data[LAST_TIME_STATE] = _last_time_state.as_dict()


func load(save_data: Dictionary) -> void:
	_try_init(_current_time_state, save_data, CURRENT_TIME_STATE)
	_try_init(_last_time_state, save_data, LAST_TIME_STATE)

	_set_time()


func _try_init(time_state: TimeState, dict: Dictionary, key: String) -> void:
	if dict.has(key) and dict[key] is Dictionary:
		time_state.init_from_dict(dict[key])


func _set_time() -> void:
	_l_time.text = _time_text_template % [
		_current_time_state.elapsed_time / 3600.0,
		fmod(_current_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_current_time_state.elapsed_time, 60.0),
		fmod(_current_time_state.elapsed_time, 1) * 100.0
	]


class TimeState extends Object:
	const ELAPSED_TIME := &"elapsed_time"
	const RESUMED_TIMES := &"resumed_times"
	const PAUSED_TIMES := &"paused_times"

	var elapsed_time: float = 0.0
	var resumed_times: Array[float]
	var paused_times: Array[float]

	func init_from_dict(dict: Dictionary) -> void:
		if dict.has(ELAPSED_TIME):
			elapsed_time = dict[ELAPSED_TIME]
		
		if dict.has(RESUMED_TIMES):
			resumed_times.assign(dict[RESUMED_TIMES])
		
		if dict.has(PAUSED_TIMES):
			paused_times.assign(dict[PAUSED_TIMES])


	func as_dict() -> Dictionary:
		return {
			ELAPSED_TIME: elapsed_time,
			RESUMED_TIMES: resumed_times,
			PAUSED_TIMES: paused_times,
		}
