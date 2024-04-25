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

var _time_state: TimeState = TimeState.new()
var _last_time_state: TimeState = TimeState.new()


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	set_process(false)

	await get_tree().physics_frame
	if _time_state.elapsed_time > 0.0:
		started.emit()


func _process(delta: float) -> void:
	_time_state.elapsed_time += delta
	_set_time()


func has_started() -> bool:
	return _time_state.elapsed_time > 0.0


func set_state(state: bool) -> void:
	set_process(state)

	var current_time := Time.get_datetime_dict_from_system()
	var seconds := \
		float(current_time["hour"]) * 3600.0\
		+ float(current_time["minute"]) * 60.0\
		+ float(current_time["second"])

	var time := &"%s:%02d:%02d" % [
		current_time["hour"],
		current_time["minute"],
		current_time["second"]
	]
	if state:
		modulate = _ticking_colour
		
		if _time_state.resumed_times.size() < _time_state.paused_times.size():
			_time_state.resumed_times.append(seconds)
			resumed.emit(time)
		elif _time_state.elapsed_time == 0.0:
			started.emit()
	else:
		modulate = _paused_colour

		_time_state.paused_times.append(seconds)
		paused.emit(time)



func reset() -> void:
	_last_time_state.free()
	_last_time_state = _time_state
	_time_state = TimeState.new()
	_set_time()


func restore_last_time_state() -> void:
	var temp := _time_state
	_time_state = _last_time_state
	_last_time_state = temp

	_set_time()


func get_time_short() -> String:
	return "%02d:%02d:%02d" % [
		_time_state.elapsed_time / 3600.0,
		fmod(_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_time_state.elapsed_time, 60.0)
	]


func get_paused_times_size() -> int:
	return _time_state.paused_times.size()


func get_paused_time(index: int) -> StringName:
	return _seconds_to_hour(_time_state.paused_times[index])


func get_resumed_times_size() -> int:
	return _time_state.resumed_times.size()


func get_resumed_time(index: int) -> StringName:
	return _seconds_to_hour(_time_state.resumed_times[index])


func get_pause_span(index: int) -> float:
	return _time_state.resumed_times[index] - _time_state.paused_times[index]


func delete_time_entry(index: int) -> void:
	_time_state.paused_times.remove_at(index)
	
	if _time_state.resumed_times.size() > index:
		_time_state.resumed_times.remove_at(index)


func save(save_data: Dictionary) -> void:
	save_data[CURRENT_TIME_STATE] = _time_state.as_dict()
	save_data[LAST_TIME_STATE] = _last_time_state.as_dict()


func load(save_data: Dictionary) -> void:
	_try_init(_time_state, save_data, CURRENT_TIME_STATE)
	_try_init(_last_time_state, save_data, LAST_TIME_STATE)

	_set_time()


func _try_init(time_state: TimeState, dict: Dictionary, key: String) -> void:
	if dict.has(key) and dict[key] is Dictionary:
		time_state.init_from_dict(dict[key])


func _set_time() -> void:
	_l_time.text = _time_text_template % [
		_time_state.elapsed_time / 3600.0,
		fmod(_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_time_state.elapsed_time, 60.0),
		fmod(_time_state.elapsed_time, 1.0) * 100.0
	]


func _seconds_to_hour(seconds: float) -> String:
	return &"%02d:%02d:%02d" % [
		seconds / 3600.0,
		fmod(seconds, 3600.0) / 60.0,
		fmod(seconds, 60.0)
	]

class TimeState extends Object:
	const ELAPSED_TIME := &"elapsed_time"
	const PAUSED_TIMES := &"paused_times"
	const RESUMED_TIMES := &"resumed_times"

	var elapsed_time: float = 0.0
	var paused_times: PackedFloat32Array
	var resumed_times: PackedFloat32Array

	func init_from_dict(dict: Dictionary) -> void:
		if dict.has(ELAPSED_TIME):
			elapsed_time = dict[ELAPSED_TIME]
		
		if dict.has(PAUSED_TIMES):
			paused_times = dict[PAUSED_TIMES]
		
		if dict.has(RESUMED_TIMES):
			resumed_times = dict[RESUMED_TIMES]


	func as_dict() -> Dictionary:
		return {
			ELAPSED_TIME: elapsed_time,
			PAUSED_TIMES: paused_times,
			RESUMED_TIMES: resumed_times,
		}


class DeletedEntry extends Object:
	var index: int
	var paused_time: float
	var resumed_time: float = -1


	func _init(
		_index: int = -1,
		_paused_time: float = -1.0,
		_resumed_time: float = -1
	) -> void:
		index = _index
		paused_time = _paused_time
		resumed_time = _resumed_time
