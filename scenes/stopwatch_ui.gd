class_name StopwatchUI extends Control


const TEMPLATE_LONGEST_ENTRY := &"%d Longest"
const TEMPLATE_SHORTEST_ENTRY := &"%d Shortest"

@export var _title_bar: Control

@export var _element_to_scale: Control

@export var _stopwatch: Stopwatch

@export var _b_reset: Button
@export var _b_clipboard: Button

@export_category("Start Button")
@export var _b_start: ButtonHoverTip
@export var _sprite_start: Texture2D
@export var _sprite_pause: Texture2D

@export_category("Stop tray")
@export var _scene_pause_tray_entry_ui: PackedScene
@export var _pause_tray: Control
@export var _tray_container: Control
@export var _hover_entry_colour := Color("#fc6360")

@export_category("Copied Pop Up")
@export var _copied_pop_up: Control
@export var _l_copied_time: Label

var _pause_tray_entries_ui: Array[PauseTrayEntryUI]
var _longest_pause_index: int
var _shortest_pause_index: int

var _pop_up_scale := 1.0
var _pop_up_tween: Tween


func _ready() -> void:
	_stopwatch.started.connect(_on_stopwatch_started)
	_stopwatch.paused.connect(_stopwatch_paused)
	_stopwatch.resumed.connect(_stopwatch_resumed)

	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_to_clipboard)

	GLOBAL.window.size_changed.connect(_on_window_size_changed)

	pivot_offset.y += _title_bar.size.y

	await get_tree().process_frame
	_on_window_size_changed()
	
	if _stopwatch.has_started():
		_set_b_start_continue()
	
	if _stopwatch.get_time_state().paused_times.size() > 0:
		_instantiate_pause_tray_entries(_stopwatch.get_time_state().resumed_times.size())

	_set_longest_shortest_times()


func restore_last_time_state() -> void:
	# Pauses stopwatch if running
	_b_start.button_pressed = false
	_stopwatch.restore_last_time_state()

	# Swap entries
	var to_set_in_tray: int
	var tray_size := _pause_tray_entries_ui.size()
	var time_state := _stopwatch.get_time_state()
	var paused_size := time_state.paused_times.size()
	var resumed_size := time_state.resumed_times.size()

	var remainder := tray_size - paused_size
	if remainder >= 0:
		to_set_in_tray = resumed_size

		# Delete overflow entries
		for i: int in remainder:
			_pause_tray_entries_ui.pop_back().queue_free()
		
		# Set entry with not resumed time
		if paused_size != resumed_size:
			var index := paused_size - 1
			var entry := _pause_tray_entries_ui[index]
			entry.set_pause_time(Global.seconds_to_time(time_state.paused_times[index]))
			entry.set_resume_time_empty()
	else:
		to_set_in_tray = tray_size

		_instantiate_pause_tray_entries(resumed_size - tray_size, tray_size)
	
	# Set existing matched entries
	for i: int in to_set_in_tray:
		var entry := _pause_tray_entries_ui[i]
		entry.set_pause_time(Global.seconds_to_time(time_state.paused_times[i]))
		entry.set_resume_time(Global.seconds_to_time(time_state.resumed_times[i]))
	
	tray_size = _pause_tray_entries_ui.size()
	if _longest_pause_index < tray_size:
		_clear_entry_suffix(_longest_pause_index)
	
	if _shortest_pause_index < tray_size:
		_clear_entry_suffix(_shortest_pause_index)
	
	_set_longest_shortest_times()

	_pause_tray.visible = paused_size > 0

	_set_buttons_disabled(not _stopwatch.has_started())


func undo_deleted_pause_entry() -> void:
	print("undo_deleted_pause_entry pressed")

	var time_state := _stopwatch.get_time_state()
	if not time_state.can_undo():
		print("No entries to undo")
		return
	
	var index := time_state.undo_deleted_entry()
	var new_entry := _instantiate_pause_entry(
		Global.seconds_to_time(time_state.paused_times[index]),
		index,
		_pause_tray_entries_ui.size() - index
	)
	
	if index < time_state.resumed_times.size():
		new_entry.set_resume_time(Global.seconds_to_time(time_state.resumed_times[index]))

	var tray_size := _pause_tray_entries_ui.size()
	if _longest_pause_index < tray_size and _shortest_pause_index < tray_size:
		_clear_entry_suffix(_longest_pause_index)
		_clear_entry_suffix(_shortest_pause_index)

	for i: int in range(index + 1, tray_size):
		_pause_tray_entries_ui[i].set_pause_span(str(i + 1))

	var entries_size := time_state.resumed_times.size()
	if entries_size < 2:
		return
	
	_set_longest_shortest_times()


func redo_deleted_pause_entry() -> void:
	print("redo_deleted_pause_entry pressed")

	var time_state := _stopwatch.get_time_state()
	if not time_state.can_redo():
		print("no entries to redo")
		return
	
	var index := time_state.redo_deleted_entry()
	var entry := _pause_tray_entries_ui[index]

	entry.delete_routine()

	_on_entry_deleted(_correct_index_to_delete(index, _pause_tray_entries_ui.size() - 1))


func pause_stopwatch_if_running() -> void:
	if _b_start.button_pressed:
		_stopwatch.set_state(false)


func _set_buttons_disabled(state: bool) -> void:
	_b_reset.disabled = state
	_b_clipboard.disabled = state


func _on_stopwatch_started() -> void:
	_set_buttons_disabled(false)


func _stopwatch_paused(time: StringName) -> void:
	_instantiate_pause_entry(time, _pause_tray_entries_ui.size(), 0)


func _stopwatch_resumed(time: StringName) -> void:
	_pause_tray_entries_ui.back().set_resume_time(time)

	var index := _stopwatch.get_time_state().resumed_times.size() - 1
	if index < 1:
		return

	# two entries. None has longest nor shortest
	if index == 1:
		_set_longest_shortest_times()
	else:
		var pause_span := _stopwatch.get_pause_span(index)
		# Check if new entry is new longest or shortest
		if pause_span >= _stopwatch.get_pause_span(_longest_pause_index):
			_clear_entry_suffix(_longest_pause_index)
			_longest_pause_index = index
			_set_entry_span(_longest_pause_index, TEMPLATE_LONGEST_ENTRY)
		elif pause_span <= _stopwatch.get_pause_span(_shortest_pause_index):
			_clear_entry_suffix(_shortest_pause_index)
			_shortest_pause_index = index
			_set_entry_span(_shortest_pause_index, TEMPLATE_SHORTEST_ENTRY)


func _start_toggled(state: bool) -> void:
	if state:
		_b_start.icon = _sprite_pause
		_b_start.set_tip_name("pause")
	else:
		_set_b_start_continue()

	_stopwatch.set_state(state)


func _reset_pressed() -> void:
	_b_reset.disabled = true
	_b_clipboard.disabled = true
	_b_reset.hide_hover_tip()

	_stopwatch.reset()

	_b_start.button_pressed = false
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("start")

	for entry in _pause_tray_entries_ui:
		entry.queue_free()
	
	_pause_tray_entries_ui.clear()

	_pause_tray.visible = false

	_longest_pause_index = 0
	_shortest_pause_index = 0


func _copy_to_clipboard() -> void:
	var time := _stopwatch.get_time_short()
	DisplayServer.clipboard_set(time)

	_l_copied_time.text = "Copied!\n%s" % time

	if _pop_up_tween:
		_pop_up_tween.kill()

	_copied_pop_up.scale.y = 0.0
	_copied_pop_up.visible = true
	_pop_up_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_pop_up_tween.tween_property(_copied_pop_up, "scale:y", _pop_up_scale, .25)
	_pop_up_tween.tween_interval(.75)
	_pop_up_tween.tween_callback(func() -> void: _copied_pop_up.visible = false)


func _on_window_size_changed() -> void:
	# Scale text to fit size
	var scale_x := GLOBAL.window.size.x / float(GLOBAL.window.max_size.x)
	var win_size_y := float(GLOBAL.window.size.y)
	var win_max_size_y := float(GLOBAL.window.max_size.y)
	var min_scale_y := (win_size_y + _title_bar.size.y + _stopwatch.size.y) / win_max_size_y
	var s := minf(scale_x, maxf((win_size_y / win_max_size_y) * (min_scale_y * 2.0), min_scale_y))
	_element_to_scale.scale = Vector2(s, s)

	# Slight scale s_copied
	_pop_up_scale = clampf(s * 1.025, .7, 1.0)
	_copied_pop_up.scale = Vector2(_pop_up_scale, _pop_up_scale)

	# Slight scale buttons
	var b_s := maxf(1.0, 1.75 - s)
	var b_scale = Vector2(b_s, b_s)
	_b_start.scale = b_scale
	_b_reset.scale = b_scale
	_b_clipboard.scale = b_scale


func _on_entry_hovered(entry: PauseTrayEntryUI) -> void:
	entry.modulate_animation(_hover_entry_colour)


func _on_entry_deleted(sibbling_index: int) -> void:
	var tray_size := _pause_tray_entries_ui.size() - 1
	var index := _correct_index_to_delete(sibbling_index, tray_size)
	
	_pause_tray_entries_ui[index].modulate = _hover_entry_colour
	_pause_tray_entries_ui.remove_at(index)

	var time_state := _stopwatch.get_time_state()
	time_state.delete_entry(index)

	for i: int in range(index, tray_size):
		_pause_tray_entries_ui[i].replace_pause_num(str(i + 2), str(i + 1))

	var entries_size := time_state.resumed_times.size()
	if entries_size < 2:
		if entries_size == 0 and time_state.paused_times.size() == 0:
			_pause_tray.hide()
		elif index == _longest_pause_index:
			_clear_entry_suffix(_shortest_pause_index - (0 if index != 0 else 1))
		elif index == _shortest_pause_index:
			_clear_entry_suffix(_longest_pause_index - (0 if index != 0 else 1))

		return
	
	if index == _longest_pause_index:
		var longest_span := -Global.FLOAT_MAX
		_longest_pause_index = 0

		for i in entries_size:
			var time_span := _stopwatch.get_pause_span(i)
			if time_span >= longest_span:
				longest_span = time_span
				_longest_pause_index = i
		
		_set_entry_span(_longest_pause_index, TEMPLATE_LONGEST_ENTRY)
	elif index == _shortest_pause_index:
		var shortest_span := Global.FLOAT_MAX
		_shortest_pause_index = 0

		for i in entries_size:
			var time_span := _stopwatch.get_pause_span(i)
			if time_span <= shortest_span:
				shortest_span = time_span
				_shortest_pause_index = i
		
		_set_entry_span(_shortest_pause_index, TEMPLATE_SHORTEST_ENTRY)


func _set_b_start_continue() -> void:
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("continue")


func _instantiate_pause_entry(time: StringName, insert_at: int, move_to: int) -> PauseTrayEntryUI:
	var new_entry: PauseTrayEntryUI = _scene_pause_tray_entry_ui.instantiate()
	_pause_tray_entries_ui.insert(insert_at, new_entry)
	new_entry.set_pause_span(str(insert_at + 1))
	new_entry.set_pause_time(time)

	new_entry.hovered.connect(_on_entry_hovered)
	new_entry.deleted.connect(_on_entry_deleted)

	_tray_container.add_child(new_entry)
	_tray_container.move_child(new_entry, move_to)
	
	_pause_tray.visible = true

	return new_entry


func _instantiate_pause_tray_entries(amount: int, index_offset: int = 0) -> void:
	var time_state := _stopwatch.get_time_state()
	for i in amount:
		var index := index_offset + i
		_instantiate_pause_entry(
			Global.seconds_to_time(time_state.paused_times[index]),
			i + index_offset,
			0
			)\
			.set_resume_time(Global.seconds_to_time(time_state.resumed_times[index]))
	
	_instantiate_pause_entry(
		Global.seconds_to_time(time_state.paused_times[amount + index_offset]),
		amount + index_offset,
		0
	)


func _clear_entry_suffix(index: int) -> void:
	_pause_tray_entries_ui[index].set_pause_span(str(index + 1))


func _set_entry_span(index: int, template: StringName) -> void:
	_pause_tray_entries_ui[index].set_pause_span(template % (index + 1))


func _set_longest_shortest_times() -> void:
	var resumed_size := _stopwatch.get_time_state().resumed_times.size()
	if resumed_size < 2:
		return
	
	var longest_pause_span := -Global.FLOAT_MAX
	_longest_pause_index = 0
	var shortest_pause_span := Global.FLOAT_MAX
	_shortest_pause_index = 0

	for i: int in resumed_size:
		var pause_span := _stopwatch.get_pause_span(i)
		if pause_span >= longest_pause_span:
			longest_pause_span = pause_span
			_longest_pause_index = i
		elif pause_span <= shortest_pause_span:
			shortest_pause_span = pause_span
			_shortest_pause_index = i
	
	_set_entry_span(_longest_pause_index, TEMPLATE_LONGEST_ENTRY)
	_set_entry_span(_shortest_pause_index, TEMPLATE_SHORTEST_ENTRY)


func _correct_index_to_delete(index: int, tray_size: int) -> int:
	return tray_size - index + (_tray_container.get_child_count() - 1 - tray_size)
