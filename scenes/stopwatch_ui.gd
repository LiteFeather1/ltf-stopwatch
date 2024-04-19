class_name StopwatchUI extends Control


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
var _pause_tray_entries_ui: Array[PauseTrayEntryUI]


@export_category("Copied Pop Up")
@export var _copied_pop_up: Control
@export var _l_copied_time: Label

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
	
	var resumed_size := _stopwatch.get_current_resumed_times_size()
	for i: int in resumed_size:
		_stopwatch_paused(_stopwatch.get_current_paused_time(i))
		_stopwatch_resumed(_stopwatch.get_current_resumed_time(i))
	
	if resumed_size != _stopwatch.get_current_paused_times_size():
		_stopwatch_paused(_stopwatch.get_current_paused_time(resumed_size))


func restore_last_time_state() -> void:
	_stopwatch.restore_last_time_state()

	# Swap entries
	var existing_entries: int
	var paused_size := _stopwatch.get_current_paused_times_size()
	var resumed_size := _stopwatch.get_current_resumed_times_size()
	var tray_size := _pause_tray_entries_ui.size()

	var remainder := tray_size - paused_size
	var matching_paused_resumed := paused_size == resumed_size
	if remainder >= 0:
		existing_entries = resumed_size

		# Delete overflow entries
		for i: int in remainder:
			_pause_tray_entries_ui.pop_back().queue_free()
		
		# Set entry with not resumed time
		if not matching_paused_resumed:
			var index := paused_size - 1
			var entry := _pause_tray_entries_ui[index]
			entry.set_pause_time(_stopwatch.get_current_paused_time(index))
			entry.set_resume_time_empty()
	else:
		existing_entries = tray_size

		# Spawn missing matched entries
		for i: int in resumed_size - tray_size:
			var index := tray_size + i
			_stopwatch_paused(_stopwatch.get_current_paused_time(index))
			_stopwatch_resumed(_stopwatch.get_current_resumed_time(index))
		
		# Spawn missing entry with no resumed time
		if not matching_paused_resumed:
			_stopwatch_paused(_stopwatch.get_current_paused_time(tray_size - resumed_size))
	
	# Set existing matched entries
	for i: int in existing_entries:
		var entry := _pause_tray_entries_ui[i]
		entry.set_pause_time(_stopwatch.get_current_paused_time(i))
		entry.set_resume_time(_stopwatch.get_current_resumed_time(i))
	
	_pause_tray.visible = paused_size > 0

	_b_start.button_pressed = false

	_set_buttons_disabled(not _stopwatch.has_started())


func pause_stopwatch_if_running() -> void:
	if _b_start.button_pressed:
		_stopwatch.set_state(false)


func _set_buttons_disabled(state: bool) -> void:
	_b_reset.disabled = state
	_b_clipboard.disabled = state


func _on_stopwatch_started() -> void:
	_set_buttons_disabled(false)


func _stopwatch_paused(time: StringName) -> void:
	var new_entry: PauseTrayEntryUI = _scene_pause_tray_entry_ui.instantiate()
	_pause_tray_entries_ui.append(new_entry)
	var pause_tray_size := _pause_tray_entries_ui.size()
	new_entry.set_pause_num(str(pause_tray_size))
	new_entry.set_pause_time(time)

	_tray_container.add_child(new_entry)
	_tray_container.move_child(new_entry, 0)
	
	if pause_tray_size > 0:
		_pause_tray.visible = true


func _stopwatch_resumed(time: StringName) -> void:
	_pause_tray_entries_ui.back().set_resume_time(time)


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
	var s := minf(
		scale_x,
		clampf(
			(win_size_y / win_max_size_y) * (min_scale_y * 2.0),
			min_scale_y,
			scale_x
		)
	)
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
