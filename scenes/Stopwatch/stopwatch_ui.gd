class_name StopwatchUI extends Control


enum CopyMenuFlags {
	ELAPSED_TIMES = 1 << 0,
	PAUSE_SPANS = 1 << 1,
	LONGEST_SHORTEST = 1 << 2,
}

const COPY_MENU_OPTIONS := &"copy_menu_options"

const TEMPLATE_LONGEST_ENTRY := &"#%d Longest"
const TEMPLATE_SHORTEST_ENTRY := &"#%d Shortest"

const PAUSES := &"Pauses"
const PAUSE_TIME := &"Pause Time"
const RESUME_TIME := &"Resume Time"
const ELAPSED_TIME := &"Elapsed Time"
const PAUSE_SPAN := &"Pause Span"
const LONGEST_SHORTEST := &"Longest/Shortest"
const SHORTEST_LONGEST := &"Shortest/Longest"

@export var _element_to_scale: Control

@export var _stopwatch: Stopwatch

@export var _b_reset: Button
@export var _b_clipboard: Button

@export_category("Start Button")
@export var _b_start: ButtonHoverTip
@export var _sprite_start: Texture2D
@export var _sprite_pause: Texture2D

@export_category("Entry tray")
@export var _scene_stopwatch_entry_ui: PackedScene
@export var _entry_tray: VBoxContainer
@export var _tray_container: Control
@export var _copy_menu_button: MenuButton
@export var _hover_entry_colour := Color("#fc6360")
@export var _hbc_tray_heading: HBoxContainer
@export var _tray_h_separation_range := Vector2(60.0, -20.0)

@export_category("Copied Pop Up")
@export var _copied_pop_up: Control
@export var _l_copied_time: Label

var _stopwatch_tray_entries_ui: Array[StopwatchEntryUI]
var _longest_entry_index: int
var _shortest_entry_index: int

var _menu_copy_id_to_callable: Dictionary
var _copy_menu_options_mask: int

var _win_x_for_min_h_separation: int

var _pop_up_scale := 1.0
var _pop_up_tween: Tween


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	_stopwatch.started.connect(_on_stopwatch_started)
	_stopwatch.paused.connect(_stopwatch_paused)
	_stopwatch.resumed.connect(_stopwatch_resumed)

	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_elapsed_time_to_clipboard)

	GLOBAL.window.size_changed.connect(_on_window_size_changed)

	# Find min for h separation
	var label_pause_time: Label = _hbc_tray_heading.get_child(1)
	_win_x_for_min_h_separation = int(label_pause_time.get_theme_font("font").get_string_size(
		"    %s  %s  %s    " % [
			TEMPLATE_SHORTEST_ENTRY % 99,
			label_pause_time.text,
			_hbc_tray_heading.get_child(2).text,
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_pause_time.get_theme_font_size("font_size"),
	).x)

	await get_tree().process_frame

	# Set up copy menu tray
	var pop_up := _copy_menu_button.get_popup()
	pop_up.hide_on_checkable_item_selection = false
	pop_up.id_pressed.connect(_on_copy_menu_id_pressed)

	const ITEMS := [&"Copy Simple", &"Copy Long", &"Copy CSV", &"Copy Markdown Table"]
	var items_calls := [
		_copy_menu_simple,
		_copy_menu_long,
		_copy_menu_csv,
		_copy_menu_markdown,
	]
	var items_size := ITEMS.size()
	for i: int in items_size:
		pop_up.add_item(ITEMS[i], i)
		_menu_copy_id_to_callable[i] = items_calls[i]

	pop_up.add_separator("| Options |")

	const OPTIONS := [ELAPSED_TIME, PAUSE_SPAN, &"Longest/Shortest"]
	var options_calls := [
		_copy_menu_toggle_elapsed_time,
		_copy_menu_toggle_pause_time,
		_copy_menu_toggle_shortest_longest,
	]
	var options_flags_values := CopyMenuFlags.values()
	for i: int in OPTIONS.size():
		var index := i + items_size + 1
		_menu_copy_id_to_callable[index] = options_calls[i]

		pop_up.add_check_item(OPTIONS[i], index)
		if _copy_menu_options_mask & options_flags_values[i] != 0:
			pop_up.set_item_checked(index, true)

	_on_window_size_changed()
	
	if _stopwatch.has_started():
		_set_b_start_continue()
	
	var time_state := _stopwatch.get_time_state()
	if time_state.paused_times_size() > 0:
		_instantiate_stopwatch_entries_ui(time_state.resumed_times_size())

		_find_longest_shortest_times()


func restore_last_time_state() -> void:
	# Pauses stopwatch if running
	_b_start.button_pressed = false
	_stopwatch.restore_last_time_state()

	# Swap entries
	var to_set_in_tray: int
	var tray_size := _stopwatch_tray_entries_ui.size()
	var time_state := _stopwatch.get_time_state()
	var paused_size := time_state.paused_times_size()
	var resumed_size := time_state.resumed_times_size()

	var remainder := tray_size - paused_size
	if remainder >= 0:
		to_set_in_tray = resumed_size

		# Delete overflow entries
		for i: int in remainder:
			_stopwatch_tray_entries_ui.pop_back().queue_free()
		
		# Set entry with not resumed time
		if paused_size != resumed_size:
			var index := paused_size - 1
			_stopwatch_tray_entries_ui[index].set_times(
				Time.get_time_string_from_unix_time(time_state.get_paused_time(index)),
				TimeState.NIL_PAUSE_TEXT,
				Global.seconds_to_time(time_state.get_elapsed_time(index)),
			)
	else:
		to_set_in_tray = tray_size

		_instantiate_stopwatch_entries_ui(resumed_size - tray_size, tray_size)
	
	# Set existing matched entries
	for i: int in to_set_in_tray:
		_stopwatch_tray_entries_ui[i].set_times(
			Time.get_time_string_from_unix_time(time_state.get_paused_time(i)),
			Time.get_time_string_from_unix_time(time_state.get_resumed_time(i)),
			Global.seconds_to_time(time_state.get_elapsed_time(i)),
		)
	
	tray_size = _stopwatch_tray_entries_ui.size()
	if _longest_entry_index < tray_size:
		_clear_entry_suffix(_longest_entry_index)
	
	if _shortest_entry_index < tray_size:
		_clear_entry_suffix(_shortest_entry_index)
	
	_find_longest_shortest_times()

	_set_entry_tray_visibility(paused_size > 0)
	_set_buttons_disabled(not _stopwatch.has_started())

	AL_HoverTipFollow.hide_hover_tip()


func undo_deleted_stopwatch_entry_ui() -> void:
	var time_state := _stopwatch.get_time_state()
	if not time_state.can_undo():
		return
	
	_set_entry_tray_visibility()
	
	var index := time_state.undo_deleted_entry()
	var new_entry := _instantiate_stopwatch_entry_ui(
		index, _stopwatch_tray_entries_ui.size() - index, get_h_separation_entry_tray()
	)
	
	var resumed_size := time_state.resumed_times_size()
	if index < resumed_size:
		new_entry.set_resume_time(
			Time.get_time_string_from_unix_time(time_state.get_resumed_time(index))
		)

	for i: int in range(index + 1, _stopwatch_tray_entries_ui.size()):
		_stopwatch_tray_entries_ui[i].set_pause_span("#%d" % (i + 1))

	if resumed_size < 2:
		return
	else:
		_clear_entry_suffix(_longest_entry_index)
		_clear_entry_suffix(_shortest_entry_index)

		_find_longest_shortest_times()


func redo_deleted_stopwatch_entry_ui() -> void:
	var time_state := _stopwatch.get_time_state()
	if not time_state.can_redo():
		return
	
	var index := time_state.redo_deleted_entry()

	_stopwatch_tray_entries_ui[index].delete_routine()

	_delete_stopwatch_entry_ui(index)


func pause_stopwatch_if_running() -> void:
	if _b_start.button_pressed:
		_stopwatch.set_state(false)


func load(save_data: Dictionary) -> void:
	if save_data.has(COPY_MENU_OPTIONS):
		_copy_menu_options_mask = save_data[COPY_MENU_OPTIONS]


func save(save_data: Dictionary) -> void:
	save_data[COPY_MENU_OPTIONS] = _copy_menu_options_mask


func _set_buttons_disabled(state: bool) -> void:
	_b_reset.disabled = state
	_b_clipboard.disabled = state


func _on_stopwatch_started() -> void:
	_set_buttons_disabled(false)


func _stopwatch_paused() -> void:
	_instantiate_stopwatch_entry_ui(_stopwatch_tray_entries_ui.size(), 0, get_h_separation_entry_tray())

	_set_entry_tray_visibility()


func _stopwatch_resumed() -> void:
	var time_state = _stopwatch.get_time_state()
	var index := time_state.resumed_times_size() - 1
	_stopwatch_tray_entries_ui.back().set_resume_time(
		Time.get_time_string_from_unix_time(time_state.get_resumed_time(index))
	)

	if index < 1:
		return

	# Two entries. None has longest nor shortest
	if index == 1:
		_find_longest_shortest_times()
	else:
		var pause_span := time_state.pause_span(index)
		# Check if new entry is new longest or shortest
		if pause_span >= time_state.pause_span(_longest_entry_index):
			_clear_entry_suffix(_longest_entry_index)
			_longest_entry_index = index
			_set_entry_span(_longest_entry_index, TEMPLATE_LONGEST_ENTRY)
		elif pause_span <= time_state.pause_span(_shortest_entry_index):
			_clear_entry_suffix(_shortest_entry_index)
			_shortest_entry_index = index
			_set_entry_span(_shortest_entry_index, TEMPLATE_SHORTEST_ENTRY)


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

	for entry: StopwatchEntryUI in _stopwatch_tray_entries_ui:
		entry.queue_free()
	
	_stopwatch_tray_entries_ui.clear()

	_set_entry_tray_visibility(false)

	_longest_entry_index = 0
	_shortest_entry_index = 0


func _set_clipboard(to_copy: String, message: String) -> void:
	DisplayServer.clipboard_set(to_copy)
	print("Clipboard set to:\n%s" % to_copy)

	_l_copied_time.text = "Copied!\n%s" % message

	if _pop_up_tween:
		_pop_up_tween.kill()

	_copied_pop_up.scale.y = 0.0
	_copied_pop_up.visible = true

	_pop_up_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_pop_up_tween.tween_property(_copied_pop_up, "scale:y", _pop_up_scale, .25)
	_pop_up_tween.tween_callback(func() -> void:
		_copied_pop_up.visible = false
	).set_delay(.66)


func _copy_elapsed_time_to_clipboard() -> void:
	var time := Global.seconds_to_time(_stopwatch.get_time_state().elapsed_time)
	_set_clipboard(time, time)


func _on_copy_menu_id_pressed(index: int) -> void:
	_menu_copy_id_to_callable[index].call(index)


func _copy_menu_tray_entries(
	message: String,
	entries_text: PackedStringArray,
	template: String,
	template_elapsed_time: String,
	template_pause_span: String,
	template_longest_shortest: String,
) -> void:
	var time_state := _stopwatch.get_time_state()
	var resumed_size := time_state.resumed_times_size()
	var base_size := entries_text.size()

	var show_elapsed_time := _copy_menu_options_mask & CopyMenuFlags.ELAPSED_TIMES != 0
	var show_pause_span := _copy_menu_options_mask & CopyMenuFlags.PAUSE_SPANS != 0
	var show_longest_shortest := (
		_copy_menu_options_mask & CopyMenuFlags.LONGEST_SHORTEST != 0
		and resumed_size > 1
	)

	if resumed_size == time_state.paused_times_size():
		entries_text.resize(resumed_size + base_size)
	else:
		entries_text.resize(resumed_size + base_size + 1)

		entries_text[resumed_size + base_size] = template % [
			resumed_size + 1,
			(template_elapsed_time % Global.seconds_to_time(time_state.get_elapsed_time(resumed_size)))
				if show_elapsed_time else "",
			Time.get_time_string_from_unix_time(time_state.get_paused_time(resumed_size)),
			time_state.NIL_PAUSE_TEXT_SPACED,
			(template_pause_span % time_state.NIL_PAUSE_TEXT_SPACED) if show_pause_span else "",
			(template_longest_shortest % "--") if show_longest_shortest else "",
		]

	var pause_span_indexes: PackedInt32Array
	if show_longest_shortest:
		pause_span_indexes = time_state.pause_span_indexes()
	for i: int in resumed_size:
		entries_text[i + base_size] = template % [
			i + 1,
			(template_elapsed_time % Global.seconds_to_time(time_state.get_elapsed_time(i)))
				if show_elapsed_time else "",
			Time.get_time_string_from_unix_time(time_state.get_paused_time(i)),
			Time.get_time_string_from_unix_time(time_state.get_resumed_time(i)),
			(template_pause_span % Global.seconds_to_time(time_state.pause_span(i)))
				if show_pause_span else "",
			(template_longest_shortest % "#%d" % pause_span_indexes[i])
				if show_longest_shortest else ""
		]
	
	if show_longest_shortest:
		entries_text[base_size + _longest_entry_index] = entries_text[base_size + _longest_entry_index].replace(
			template_longest_shortest % "#%d" % (resumed_size - 1), template_longest_shortest % "Longest"
		)
		entries_text[base_size + _shortest_entry_index] = entries_text[base_size + _shortest_entry_index].replace(
			template_longest_shortest % "#%d" % 0, template_longest_shortest % "Shortest"
		)

	_set_clipboard("\n".join(entries_text), message)


func _copy_menu_simple(_index: int) -> void:
	_copy_menu_tray_entries("Simple", PackedStringArray(),
		"#%s  %s%s  %s%s%s", "%s  ", "  %s", "  %s"
	)


func _build_copy_heading(
	template_pause: String,
	template_pause_time: String,
	template_resume_time: String,
	template_elapsed_time: String,
	template_pause_span: String,
	template_longest_shortest: String,
) -> PackedStringArray:
	var heading := PackedStringArray([
		template_pause % PAUSES,
		template_pause_time % PAUSE_TIME,
		template_resume_time % RESUME_TIME,
	])

	if _copy_menu_options_mask & CopyMenuFlags.ELAPSED_TIMES != 0:
		heading.insert(1, template_elapsed_time % ELAPSED_TIME)

	if _copy_menu_options_mask & CopyMenuFlags.PAUSE_SPANS != 0:
		heading.append(template_pause_span % PAUSE_SPAN)

	if (
		_copy_menu_options_mask & CopyMenuFlags.LONGEST_SHORTEST
		and _stopwatch.get_time_state().resumed_times_size() > 1
	):
		heading.append(template_longest_shortest % (
			LONGEST_SHORTEST if _longest_entry_index < _shortest_entry_index else SHORTEST_LONGEST
		))

	return heading


func _copy_menu_long(_index: int) -> void:
	var entries_text := PackedStringArray(["".join(_build_copy_heading(
		"%s  |", "  %s  |", "  %s", "  %s  |", "  |  %s", "  |  %s"
	))])
	_copy_menu_tray_entries("Long", entries_text,
		"#%s          %s|     %s     |     %s%s%s", "|      %s       ", "        |    %s", (
			"     |  %s" if _copy_menu_options_mask & CopyMenuFlags.PAUSE_SPANS != 0 else "        |  %s"
		),
	)


func _copy_menu_csv(_index: int) -> void:
	var entries_text := PackedStringArray(["".join(
		_build_copy_heading("%s,", "%s,", "%s", "%s,", ",%s", ",%s"
	))])
	_copy_menu_tray_entries("CSV", entries_text, "#%s,%s%s,%s%s%s", "%s,", ",%s", ",%s")


func _copy_menu_markdown(_index: int) -> void:
	var heading := _build_copy_heading("|%s", "|%s", "|%s|", "|%s", "%s|", "%s|")
	var heading_size := heading.size()
	heading.resize(heading_size * 2 + 1)
	heading[heading_size] = "\n"
	heading[heading_size + 1] = "|:-|"
	for i: int in heading_size - 2:
		heading[i + heading_size + 2] = ":-:|"
	
	heading[heading_size * 2] =\
		":-|" if (_copy_menu_options_mask & CopyMenuFlags.LONGEST_SHORTEST != 0) else ":-:|"

	_copy_menu_tray_entries("MD Table", PackedStringArray(["".join(heading)]),
		"|#%s%s|%s|%s|%s%s", "|%s", "%s|", "%s|"
	)


func _copy_menu_toggle_options(index: int, flag: int) -> void:
	var is_option_checked := _copy_menu_options_mask & flag != 0
	_copy_menu_button.get_popup().set_item_checked(index, not is_option_checked)

	if is_option_checked:
		_copy_menu_options_mask = _copy_menu_options_mask & ~flag
	else:
		_copy_menu_options_mask = _copy_menu_options_mask | flag


func _copy_menu_toggle_elapsed_time(index: int) -> void:
	_copy_menu_toggle_options(index, CopyMenuFlags.ELAPSED_TIMES)


func _copy_menu_toggle_shortest_longest(index: int) -> void:
	_copy_menu_toggle_options(index, CopyMenuFlags.LONGEST_SHORTEST)


func _copy_menu_toggle_pause_time(index: int) -> void:
	_copy_menu_toggle_options(index, CopyMenuFlags.PAUSE_SPANS)


func _on_window_size_changed() -> void:
	# Scale text to fit size
	var scale_x := GLOBAL.window.size.x / float(GLOBAL.window.max_size.x)
	var win_size_y := float(GLOBAL.window.size.y)
	var win_max_size_y := float(GLOBAL.window.max_size.y)
	var min_scale_y := (win_size_y + _stopwatch.size.y + _stopwatch.pivot_offset.y) / win_max_size_y
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

	# Change tray h separation
	if _stopwatch_tray_entries_ui and _set_entry_tray_visibility():
		var separation := get_h_separation_entry_tray()
		_hbc_tray_heading.add_theme_constant_override("separation", separation)
		for entry: StopwatchEntryUI in _stopwatch_tray_entries_ui:
			entry.add_theme_constant_override("separation", separation)


func _on_stopwatch_entry_hovered(entry: StopwatchEntryUI) -> void:
	entry.modulate_animation(_hover_entry_colour)


func _on_stopwatch_entry_deleted(entry: StopwatchEntryUI) -> void:
	_delete_stopwatch_entry_ui(_stopwatch_tray_entries_ui.find(entry))


func _set_b_start_continue() -> void:
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("continue")


func _set_entry_tray_visibility(
	visibility: bool = GLOBAL.window.size.x > _win_x_for_min_h_separation,
) -> bool:
	if visibility != _entry_tray.visible:
		_entry_tray.visible = visibility

		# TODO Animation

	return visibility


func get_h_separation_entry_tray() -> int:
	return int(remap(
		GLOBAL.window.size.x,
		GLOBAL.window.max_size.x,
		_win_x_for_min_h_separation,
		_tray_h_separation_range.x,
		_tray_h_separation_range.y,
	))


func _instantiate_stopwatch_entry_ui(insert_at: int, move_to: int, separation: int) -> StopwatchEntryUI:
	var new_entry: StopwatchEntryUI = _scene_stopwatch_entry_ui.instantiate()
	_stopwatch_tray_entries_ui.insert(insert_at, new_entry)

	var time_state := _stopwatch.get_time_state()
	new_entry.init(
		"#%d" % (insert_at + 1),
		Time.get_time_string_from_unix_time(time_state.get_paused_time(insert_at)),
		Global.seconds_to_time(time_state.get_elapsed_time(insert_at)),
		_on_stopwatch_entry_hovered,
		_on_stopwatch_entry_deleted,
		separation,
	)

	_tray_container.add_child(new_entry)
	_tray_container.move_child(new_entry, move_to)

	return new_entry


func _instantiate_stopwatch_entries_ui(amount: int, index_offset: int = 0) -> void:
	var time_state := _stopwatch.get_time_state()
	var separation := get_h_separation_entry_tray()
	for i: int in amount:
		var index := index_offset + i
		_instantiate_stopwatch_entry_ui(i + index_offset, 0, separation)\
			.set_resume_time(Time.get_time_string_from_unix_time(time_state.get_resumed_time(index)))
	
	if (amount + index_offset) < time_state.paused_times_size():
		_instantiate_stopwatch_entry_ui(amount + index_offset, 0, separation)


func _delete_stopwatch_entry_ui(index: int) -> void:
	_stopwatch_tray_entries_ui[index].modulate = _hover_entry_colour
	_stopwatch_tray_entries_ui.remove_at(index)

	var time_state := _stopwatch.get_time_state()
	time_state.delete_entry(index)

	for i: int in range(index, _stopwatch_tray_entries_ui.size()):
		_stopwatch_tray_entries_ui[i].replace_pause_num("#%d" % (i + 2), str(i + 1))

	var was_longest := index == _longest_entry_index
	var was_shortest := index == _shortest_entry_index

	if index < _shortest_entry_index:
		_shortest_entry_index -= 1

	if index < _longest_entry_index:
		_longest_entry_index -= 1

	var entries_size := time_state.resumed_times_size()
	if entries_size < 2:
		if entries_size == 0 and time_state.paused_times_size() == 0:
			_entry_tray.hide()
		elif was_longest:
			_clear_entry_suffix(_shortest_entry_index)
		elif was_shortest:
			_clear_entry_suffix(_longest_entry_index)

		return
	
	if was_longest:
		var longest_span := -Global.FLOAT_MAX
		_longest_entry_index = 0

		for i:int in entries_size:
			var time_span := time_state.pause_span(i)
			if time_span >= longest_span and i != _shortest_entry_index:
				longest_span = time_span
				_longest_entry_index = i
		
		_set_entry_span(_longest_entry_index, TEMPLATE_LONGEST_ENTRY)
	elif was_shortest:
		var shortest_span := Global.FLOAT_MAX
		_shortest_entry_index = 0

		for i: int in entries_size:
			var time_span := time_state.pause_span(i)
			if time_span <= shortest_span and i != _longest_entry_index:
				shortest_span = time_span
				_shortest_entry_index = i

		_set_entry_span(_shortest_entry_index, TEMPLATE_SHORTEST_ENTRY)


func _clear_entry_suffix(index: int) -> void:
	_stopwatch_tray_entries_ui[index].set_pause_span("#%d" % (index + 1))


func _set_entry_span(index: int, template: StringName) -> void:
	_stopwatch_tray_entries_ui[index].set_pause_span(template % (index + 1))


func _find_longest_shortest_times() -> void:
	var time_state := _stopwatch.get_time_state()
	var resumed_size := time_state.resumed_times_size()
	if resumed_size < 2:
		return
	
	var longest_pause_span := -Global.FLOAT_MAX
	_longest_entry_index = 0
	var shortest_pause_span := Global.FLOAT_MAX
	_shortest_entry_index = 0

	for i: int in resumed_size:
		var pause_span := time_state.pause_span(i)
		if pause_span >= longest_pause_span:
			longest_pause_span = pause_span
			_longest_entry_index = i

		if pause_span < shortest_pause_span:
			shortest_pause_span = pause_span
			_shortest_entry_index = i
	
	_set_entry_span(_longest_entry_index, TEMPLATE_LONGEST_ENTRY)
	_set_entry_span(_shortest_entry_index, TEMPLATE_SHORTEST_ENTRY)
