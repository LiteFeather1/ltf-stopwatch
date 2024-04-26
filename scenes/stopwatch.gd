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


func get_time_state() -> TimeState:
	return _time_state


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
			_time_state.clear_redo()
			resumed.emit(time)
		elif _time_state.elapsed_time == 0.0:
			started.emit()
	else:
		modulate = _paused_colour

		_time_state.paused_times.append(seconds)
		_time_state.clear_redo()
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
	return Global.seconds_to_time(_time_state.elasped_time)


func get_pause_span(index: int) -> float:
	return _time_state.resumed_times[index] - _time_state.paused_times[index]


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


class TimeState extends Object:
	const ELAPSED_TIME := &"elapsed_time"
	const PAUSED_TIMES := &"paused_times"
	const RESUMED_TIMES := &"resumed_times"

	var elapsed_time: float = 0.0
	var paused_times: PackedFloat32Array
	var resumed_times: PackedFloat32Array

	var _deleted_entries: Array[DeletedEntry]
	var _redo_deleted_indexes: PackedInt32Array


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


	func delete_entry(index: int) -> void:
		var deleted_entry := DeletedEntry.new(index, paused_times[index])

		paused_times.remove_at(index)

		if index < resumed_times.size():
			deleted_entry.resumed_time = resumed_times[index]
			resumed_times.remove_at(index)
		
		_deleted_entries.append(deleted_entry)
		print("Deleted: ", deleted_entry)


	func undo_deleted_entry() -> bool:
		if _deleted_entries.is_empty():
			return false
	
		var deleted_entry: DeletedEntry = _deleted_entries.pop_back()

		_redo_deleted_indexes.append(deleted_entry.index)

		paused_times.insert(deleted_entry.index, deleted_entry.paused_time)

		if deleted_entry.resumed_time >= 0.0:
			resumed_times.insert(deleted_entry.index, deleted_entry.resumed_time)

		print("Undone: ", deleted_entry)
		deleted_entry.free()
		return true


	func redo_deleted_entry() -> bool:
		if _redo_deleted_indexes.is_empty():
			return false
		
		var last_index := _redo_deleted_indexes.size() - 1
		delete_entry(_redo_deleted_indexes[last_index])
		_redo_deleted_indexes.remove_at(last_index)

		return true


	func clear_redo() -> void:
		if not _redo_deleted_indexes.is_empty():
			_redo_deleted_indexes.clear()


# We could use a command pattern here
class DeletedEntry extends Object:
	var index: int
	var paused_time: float
	var resumed_time: float = -1.0


	func _init(
		_index: int = -1,
		_paused_time: float = -1.0,
	) -> void:
		index = _index
		paused_time = _paused_time


	func _to_string() -> String:
		return "Index: %d, Paused time: %s, %s" % [
			index,
			Global.seconds_to_time(paused_time),
			"Resumed Time: %s" % Global.seconds_to_time(resumed_time) if resumed_time != -1 else "No Resume time"
		]
