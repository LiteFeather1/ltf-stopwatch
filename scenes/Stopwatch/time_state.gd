class_name TimeState extends Object


const ELAPSED_TIME := &"elapsed_time"
const PAUSED_TIMES := &"paused_times"
const RESUMED_TIMES := &"resumed_times"

var elapsed_time: float = 0.0
var _paused_times: PackedFloat32Array
var _resumed_times: PackedFloat32Array

var _deleted_entries: Array[DeletedEntry]
var _redo_deleted_indexes: PackedInt32Array
var _unmatched_paused_index: int = -1


func init_from_dict(dict: Dictionary) -> void:
	if dict.has(ELAPSED_TIME):
		elapsed_time = dict[ELAPSED_TIME]
	
	if dict.has(PAUSED_TIMES):
		_paused_times = dict[PAUSED_TIMES]
	
	if dict.has(RESUMED_TIMES):
		_resumed_times = dict[RESUMED_TIMES]


func as_dict() -> Dictionary:
	return {
		ELAPSED_TIME: elapsed_time,
		PAUSED_TIMES: _paused_times,
		RESUMED_TIMES: _resumed_times,
	}


func is_ticking() -> bool:
	return _resumed_times.size() < _paused_times.size()


func append_paused_time(time: float) -> void:
	if _unmatched_paused_index != -1:
		_deleted_entries[_unmatched_paused_index].resumed_time = time
		_unmatched_paused_index = -1
	
	_paused_times.append(time)


func get_paused_time(index: int) -> float:
	return _paused_times[index]


func paused_times_size() -> int:
	return _paused_times.size()


func append_resumed_time(time: float) -> void:
	_unmatched_paused_index = -1
	_resumed_times.append(time)


func get_resumed_time(index: int) -> float:
	return _resumed_times[index]


func resumed_times_size() -> int:
	return _resumed_times.size()


func pause_span(index: int) -> float:
	return _resumed_times[index] - _paused_times[index]


func delete_entry(index: int) -> void:
	var deleted_entry := DeletedEntry.new(index, _paused_times[index])

	_paused_times.remove_at(index)

	if index < _resumed_times.size():
		deleted_entry.resumed_time = _resumed_times[index]
		_resumed_times.remove_at(index)
	else:
		_unmatched_paused_index = _deleted_entries.size()
	
	_deleted_entries.append(deleted_entry)
	print("Deleted: ", deleted_entry)

	var last_redo_index := _redo_deleted_indexes.size() - 1
	if last_redo_index != -1:
		if index == _redo_deleted_indexes[last_redo_index]:
			_redo_deleted_indexes.remove_at(last_redo_index)
		else:
			_redo_deleted_indexes.clear()


func can_undo() -> bool:
	return not _deleted_entries.is_empty()


func can_redo() -> bool:
	return not _redo_deleted_indexes.is_empty()


func undo_deleted_entry() -> int:
	var deleted_entry: DeletedEntry = _deleted_entries.pop_back()
	var index := deleted_entry.index

	_redo_deleted_indexes.append(index)

	_paused_times.insert(index, deleted_entry.paused_time)

	if deleted_entry.resumed_time >= 0.0:
		_resumed_times.insert(index, deleted_entry.resumed_time)

	print("Undone: ", deleted_entry)
	deleted_entry.free()
	return index


func redo_deleted_entry() -> int:
	return _redo_deleted_indexes[_redo_deleted_indexes.size() - 1]


func clear_redo() -> void:
	if not _redo_deleted_indexes.is_empty():
			_redo_deleted_indexes.clear()


# We could use a command pattern instead of this
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
