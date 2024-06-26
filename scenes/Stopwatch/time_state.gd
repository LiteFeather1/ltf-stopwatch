class_name TimeState extends Object


const NIL_PAUSE_TEXT := &"--:--:--"
const NIL_PAUSE_TEXT_SPACED := &" -- : -- : -- "

const SAVE_KEYS: PackedStringArray = [
	"elapsed_time",
	"_paused_times",
	"_elapsed_times",
	"_resumed_times",
]

var elapsed_time: float = 0.0

var _paused_times: PackedInt32Array
var _elapsed_times: PackedFloat32Array
var _resumed_times: PackedInt32Array

var _deleted_entries: Array[DeletedEntry]
var _redo_deleted_indexes: PackedInt32Array
var _unmatched_paused_index: int = -1


func _init(elapsed_time_: float = 0.0) -> void:
	elapsed_time = elapsed_time_


func _to_string() -> String:
	var text := "Total Elapsed Time: %s\n" % Global.seconds_to_time(elapsed_time)

	var resumed_size := _resumed_times.size()
	const TEMPLATE_ENTRY := "Elapsed Time: %s | Pause time: %s | Resumed time: %s\n"
	for i: int in resumed_size:
		text += TEMPLATE_ENTRY % [
			Global.seconds_to_time(_elapsed_times[i]),
			Time.get_time_string_from_unix_time(_paused_times[i]),
			Time.get_time_string_from_unix_time(_resumed_times[i]),
		]
	
	if resumed_size < _paused_times.size():
		text += TEMPLATE_ENTRY % [
			Global.seconds_to_time(_elapsed_times[resumed_size]),
			Time.get_time_string_from_unix_time(_paused_times[resumed_size]),
			NIL_PAUSE_TEXT,
		]

	return text


func append_paused_time(time: int) -> void:
	if _unmatched_paused_index != -1:
		_deleted_entries[_unmatched_paused_index].resumed_time = time
		_unmatched_paused_index = -1
	
	_paused_times.append(time)
	_elapsed_times.append(elapsed_time)

	_clear_redo()


func get_paused_time(index: int) -> int:
	return _paused_times[index]


func paused_times_size() -> int:
	return _paused_times.size()


func append_resumed_time(time: int) -> void:
	_unmatched_paused_index = -1
	_resumed_times.append(time)

	_clear_redo()


func get_elapsed_time(index: int) -> float:
	return _elapsed_times[index]


func get_resumed_time(index: int) -> int:
	return _resumed_times[index]


func resumed_times_size() -> int:
	return _resumed_times.size()


func pause_span(index: int) -> int:
	return _resumed_times[index] - _paused_times[index]


func pause_span_indexes() -> PackedInt32Array:
	var resumed_size := _resumed_times.size()
	var pause_spans := PackedInt32Array()
	pause_spans.resize(resumed_size)
	var indexes := PackedInt32Array()
	indexes.resize(resumed_size)
	for i: int in resumed_size:
		pause_spans[i] = _resumed_times[i] - _paused_times[i]
		indexes[i] = i

	for i: int in resumed_size -1:
		var minI := i
		for j: int in range(i + 1, resumed_size):
			if pause_spans[indexes[j]] < pause_spans[indexes[minI]]:
				minI = j

		var temp := indexes[i]
		indexes[i] = indexes[minI]
		indexes[minI] = temp

	return indexes


func delete_entry(index: int) -> void:
	var deleted_entry := DeletedEntry.new(index, _paused_times[index], _elapsed_times[index])

	_paused_times.remove_at(index)
	_elapsed_times.remove_at(index)

	if index < _resumed_times.size():
		deleted_entry.resumed_time = _resumed_times[index]
		_resumed_times.remove_at(index)
	else:
		_unmatched_paused_index = _deleted_entries.size()
	
	_deleted_entries.append(deleted_entry)

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
	_elapsed_times.insert(index, deleted_entry.elapsed_time)

	if deleted_entry.resumed_time >= 0.0:
		_resumed_times.insert(index, deleted_entry.resumed_time)

	deleted_entry.free()
	return index


func redo_deleted_entry() -> int:
	return _redo_deleted_indexes[_redo_deleted_indexes.size() - 1]


func load(save_dict: Dictionary) -> void:
	for key: String in SAVE_KEYS:
		self[key] = save_dict[key]


func save() -> Dictionary:
	var save_dict = {}
	for key: String in SAVE_KEYS:
		save_dict[key] = self[key]
	
	return save_dict


func _clear_redo() -> void:
		_redo_deleted_indexes.clear()

# We could use a command pattern or instead of this 
class DeletedEntry extends Object:
	var index: int
	var paused_time: int
	var elapsed_time: float
	var resumed_time: int = -1


	func _init(
		index_: int = -1,
		paused_time_: int = -1,
		elapsed_time_: float = -1.0,
	) -> void:
		index = index_
		paused_time = paused_time_
		elapsed_time = elapsed_time_


	func _to_string() -> String:
		return "Index: %d | Elapsed time: %s | Paused time: %s | %s" % [
			index,
			Global.seconds_to_time(elapsed_time),
			Time.get_time_string_from_unix_time(paused_time),
			"Resumed Time: %s" % (
				Time.get_time_string_from_unix_time(resumed_time) if resumed_time != -1 else "No Resume time"
			),
		]
