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


@export_category("Copied Pop Up")
@export var _copied_pop_up: Control
@export var _l_copied_time: Label

var _pause_tray_entries_ui: Array[PauseTrayEntryUI]
var _prev_longest_pause_index: int
var _prev_shortest_pause_index: int

var _pop_up_scale := 1.0
var _pop_up_tween: Tween


func _ready() -> void:
	_stopwatch.started.connect(_on_stopwatch_started)
	_stopwatch.paused.connect(_stopwatch_paused)
	_stopwatch.resumed.connect(_stopwatch_resumed)

	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_to_clipboard)

	Global.window.size_changed.connect(_on_window_size_changed)

	pivot_offset.y += _title_bar.size.y

	await get_tree().process_frame
	_on_window_size_changed()
	
	if _stopwatch.has_started():
		_set_b_start_continue()
	
	_instantiate_pause_tray_entries(_stopwatch.get_resumed_times_size())

	_set_longest_shortest_times()


func restore_last_time_state() -> void:
	# Pauses stopwatch if running
	_b_start.button_pressed = false
	_stopwatch.restore_last_time_state()

	# Swap entries
	var to_set_in_tray: int
	var tray_size := _pause_tray_entries_ui.size()
	var paused_size := _stopwatch.get_paused_times_size()
	var resumed_size := _stopwatch.get_resumed_times_size()

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
			entry.set_pause_time(_stopwatch.get_paused_time(index))
			entry.set_resume_time_empty()
	else:
		to_set_in_tray = tray_size

		_instantiate_pause_tray_entries(resumed_size - tray_size, tray_size)
	
	# Set existing matched entries
	for i: int in to_set_in_tray:
		var entry := _pause_tray_entries_ui[i]
		entry.set_pause_time(_stopwatch.get_paused_time(i))
		entry.set_resume_time(_stopwatch.get_resumed_time(i))
	
	tray_size = _pause_tray_entries_ui.size()
	if _prev_longest_pause_index < tray_size:
		_clear_prev_entry(_prev_longest_pause_index)
	
	if _prev_shortest_pause_index < tray_size:
		_clear_prev_entry(_prev_shortest_pause_index)
	
	_set_longest_shortest_times()

	_pause_tray.visible = paused_size > 0

	_set_buttons_disabled(not _stopwatch.has_started())


func pause_stopwatch_if_running() -> void:
	if _b_start.button_pressed:
		_stopwatch.set_state(false)


func _set_buttons_disabled(state: bool) -> void:
	_b_reset.disabled = state
	_b_clipboard.disabled = state


func _on_stopwatch_started() -> void:
	_set_buttons_disabled(false)


func _stopwatch_paused(time: StringName) -> PauseTrayEntryUI:
	var new_entry: PauseTrayEntryUI = _scene_pause_tray_entry_ui.instantiate()
	_pause_tray_entries_ui.append(new_entry)
	var pause_tray_size := _pause_tray_entries_ui.size()
	new_entry.set_pause_num(str(pause_tray_size))
	new_entry.set_pause_time(time)

	_tray_container.add_child(new_entry)
	_tray_container.move_child(new_entry, 0)
	
	_pause_tray.visible = true

	return new_entry


func _stopwatch_resumed(time: StringName) -> void:
	_pause_tray_entries_ui.back().set_resume_time(time)

	var index := _stopwatch.get_resumed_times_size() - 1
	if index < 1:
		return

	# two entries. None has longest nor shortest
	if index == 1:
		_set_longest_shortest_times()
	else:
		var pause_span := _stopwatch.get_pause_span(index)
		# Check if new entry is new longest or shortest
		if pause_span >= _stopwatch.get_pause_span(_prev_longest_pause_index):
			_clear_prev_entry(_prev_longest_pause_index)
			_prev_longest_pause_index = _set_entry_span(index, TEMPLATE_LONGEST_ENTRY)
		elif pause_span <= _stopwatch.get_pause_span(_prev_shortest_pause_index):
			_clear_prev_entry(_prev_shortest_pause_index)
			_prev_shortest_pause_index = _set_entry_span(index, TEMPLATE_SHORTEST_ENTRY)


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

	_prev_longest_pause_index = 0
	_prev_shortest_pause_index = 0


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
	var scale_x := Global.window.size.x / float(Global.window.max_size.x)
	var win_size_y := float(Global.window.size.y)
	var win_max_size_y := float(Global.window.max_size.y)
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


func _set_b_start_continue() -> void:
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("continue")


func _instantiate_pause_tray_entries(amount: int, index_offset: int = 0) -> void:
	for i in amount:
		var index := index_offset + i
		_stopwatch_paused(_stopwatch.get_paused_time(index))\
			.set_resume_time(_stopwatch.get_resumed_time(index))
	
	if amount != _stopwatch.get_paused_times_size():
		_stopwatch_paused(_stopwatch.get_paused_time(amount + index_offset))


func _clear_prev_entry(prev_index: int) -> void:
	_pause_tray_entries_ui[prev_index].set_pause_num(str(prev_index + 1))


func _set_entry_span(index: int, template: StringName) -> int:
	_pause_tray_entries_ui[index].set_pause_num(template % (index + 1))
	return index


func _set_longest_shortest_times() -> void:
	var valid_entries_size := _stopwatch.get_resumed_times_size()
	if valid_entries_size < 2:
		return
	
	var longest_pause_span := -1.79769e308
	var longest_index := 0
	var shortest_pause_span := 1.79769e308
	var shortest_index := 0

	for i: int in valid_entries_size:
		var pause_span := _stopwatch.get_pause_span(i)
		if pause_span >= longest_pause_span:
			longest_pause_span = pause_span
			longest_index = i
		elif pause_span <= shortest_pause_span:
			shortest_pause_span = pause_span
			shortest_index = i

	_prev_longest_pause_index = _set_entry_span(longest_index, TEMPLATE_LONGEST_ENTRY)
	_prev_shortest_pause_index = _set_entry_span(shortest_index, TEMPLATE_SHORTEST_ENTRY)
