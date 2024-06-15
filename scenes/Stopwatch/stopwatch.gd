class_name Stopwatch extends VBoxContainer


signal started()
signal paused()
signal resumed()

const NAME := &"Stopwatch"

const TIME_STATE_SAVE_KEYS: PackedStringArray = [
	"_time_state",
	"_last_time_state",
]

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
	refresh_text_time()


func refresh_text_time() -> void:
	_l_time.text = _time_text_template % [
		_time_state.elapsed_time / 3600.0,
		fmod(_time_state.elapsed_time, 3600.0) / 60.0,
		fmod(_time_state.elapsed_time, 60.0),
		fmod(_time_state.elapsed_time, 1.0) * 100.0,
	]

func has_started() -> bool:
	return _time_state.elapsed_time > 0.0


func set_state(state: bool) -> void:
	set_process(state)

	var unix_time := int(
		Time.get_unix_time_from_system()
		+ 3600.0 if Time.get_datetime_dict_from_system()["dst"] else 0.0
	)
	
	if state:
		modulate = _ticking_colour
		
		if _time_state.resumed_times_size() < _time_state.paused_times_size():
			_time_state.append_resumed_time(unix_time)
			resumed.emit()
		elif _time_state.elapsed_time == 0.0:
			started.emit()
	else:
		modulate = _paused_colour

		_time_state.append_paused_time(unix_time)
		paused.emit()


func reset(reset_time: float) -> void:
	_last_time_state.free()
	_last_time_state = _time_state
	_time_state = TimeState.new(reset_time)
	refresh_text_time()


func restore_last_time_state() -> void:
	var temp := _time_state
	_time_state = _last_time_state
	_last_time_state = temp

	refresh_text_time()


func load(save_dict: Dictionary) -> void:
	for key: String in TIME_STATE_SAVE_KEYS:
		self[key].load(save_dict[key])

	refresh_text_time()


func save() -> Dictionary:
	var save_dict := {}
	for key: String in TIME_STATE_SAVE_KEYS:
		save_dict[key] = self[key].save()
	return save_dict


func _try_init(time_state: TimeState, dict: Dictionary, key: String) -> void:
	if dict.has(key) and dict[key] is Dictionary:
		time_state.load(dict[key])
