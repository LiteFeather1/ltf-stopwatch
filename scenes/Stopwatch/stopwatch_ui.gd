class_name StopwatchUI extends Control


enum CopyMenuFlags {
	ELAPSED_TIMES = 1 << 0,
	PAUSE_SPANS = 1 << 1,
	LONGEST_SHORTEST = 1 << 2,
}

const NAME := &"StopwatchUI"

const TEMPLATE_NUM_ENTRY := &"#%d"
const TEMPLATE_LONGEST_ENTRY := &"%s Longest" % TEMPLATE_NUM_ENTRY
const TEMPLATE_SHORTEST_ENTRY := &"%s Shortest" % TEMPLATE_NUM_ENTRY

const PAUSES := &"Pauses"
const PAUSE_TIME := &"Pause Time"
const RESUME_TIME := &"Resume Time"
const ELAPSED_TIME := &"Elapsed Time"
const PAUSE_SPAN := &"Pause Span"
const LONGEST_SHORTEST := &"Longest/Shortest"
const SHORTEST_LONGEST := &"Shortest/Longest"

const TRAY_DISAPPEAR_DUR := .5

const SAVE_KEYS: PackedStringArray = [
	&"_copy_menu_options_mask",
	&"_is_entry_tray_folded",
]

@export var _vbc_stopwatch_and_buttons: VBoxContainer

@export var _stopwatch: Stopwatch

@export var _b_reset: Button
@export var _b_clipboard: Button

@export_category("Start Button")
@export var _b_start: ButtonHoverTip
@export var _sprite_start: Texture2D
@export var _sprite_pause: Texture2D

@export_category("Entry tray")
@export var _scene_stopwatch_entry_ui: PackedScene
@export var _vbc_entry_tray: VBoxContainer
@export var _vbc_entry_container: VBoxContainer
@export var _copy_menu_button: MenuButton
@export var _hover_entry_colour := Color("#fc6360")
@export var _hbc_tray_heading: HBoxContainer
@export var _copy_menu_items_icons: Array[Texture2D]
@export var _tray_h_separation_range := Vector2(60.0, -20.0)
@export var _b_toggle_fold_tray: ButtonHoverTip
@export var _c_icon_fold_tray: Control

@export_category("Copied Pop Up")
@export var _copied_pop_up: Control
@export var _l_copied_time: Label

var _stopwatch_and_buttons_separation: int

var _entry_tray_separation: int
var _entry_tray_heading_height: float
var _window_height_to_disappear_tray: float

var _is_entry_tray_visible: bool
var _is_entry_tray_folded: bool
var _entry_tray_tween: Tween

var _stopwatch_tray_entries_ui: Array[StopwatchEntryUI]
var _longest_entry_index: int
var _shortest_entry_index: int

var _copy_menu_options_mask: int

var _copy_menu_callables: Array

var _options_menu_popup: PopupMenu
var _options_menu_callables: Array

var _width_for_min_h_separation: int

var _pop_up_scale := 1.0
var _pop_up_tween: Tween


func _enter_tree() -> void:
	add_to_group(Main.SAVEABLE)


func _ready() -> void:
	# Connect to signals
	_stopwatch.started.connect(_on_stopwatch_started)
	_stopwatch.paused.connect(_stopwatch_paused)
	_stopwatch.resumed.connect(_stopwatch_resumed)

	_b_start.toggled.connect(_start_toggled)
	_b_reset.pressed.connect(_reset_pressed)
	_b_clipboard.pressed.connect(_copy_elapsed_time_to_clipboard)

	_b_toggle_fold_tray.pressed.connect(_toggle_fold_tray)

	GLOBAL.window.size_changed.connect(_on_window_size_changed)

	# Set sizes
	_stopwatch_and_buttons_separation = _vbc_stopwatch_and_buttons.get_theme_constant("separation")

	_entry_tray_separation = _vbc_entry_tray.get_theme_constant("separation")

	_entry_tray_heading_height = (
		+ _entry_tray_separation * 2
		+ _hbc_tray_heading.size.y * 2.0
		+ _vbc_entry_tray.get_child(1).size.y
	)

	var temp_entry := _scene_stopwatch_entry_ui.instantiate()
	var entry_height: float = temp_entry.size.y
	temp_entry.free()

	var label_pause_time: Label = _hbc_tray_heading.get_child(1)
	_width_for_min_h_separation = int(label_pause_time.get_theme_font("font").get_string_size(
		"%s%s%s" % [
			TEMPLATE_SHORTEST_ENTRY % 69,
			label_pause_time.text,
			_hbc_tray_heading.get_child(2).text,
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_pause_time.get_theme_font_size("font_size"),
	).x + size.x - _vbc_entry_tray.size.x)

	var parent_height := get_parent_area_size().y

	await get_tree().process_frame

	_window_height_to_disappear_tray = (
		_entry_tray_heading_height
		+ entry_height
		+ _entry_tray_separation
		+ (parent_height - size.y) # Title bar size
	)

	_vbc_stopwatch_and_buttons.pivot_offset = Vector2(
		_vbc_stopwatch_and_buttons.size.x * .5,
		_vbc_stopwatch_and_buttons.size.y * .5 + _stopwatch.get_theme_constant("separation")
	)

	# Set up copy menu tray
	var popup := _copy_menu_button.get_popup()
	popup.submenu_popup_delay = .1
	# This doesn't seem like a very save way to do this but don't know any other way since get_child(0) doen't seem to work
	popup.get_node(^"@MarginContainer@8/@ScrollContainer@9/@Control@10")\
		.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	popup.index_pressed.connect(_on_copy_menu_id_pressed)

	const ITEMS := [&"Copy Simple", &"Copy Long", &"Copy CSV", &"Copy MD Table"]
	var items_calls := [
		_copy_menu_simple,
		_copy_menu_long,
		_copy_menu_csv,
		_copy_menu_markdown,
	]
	var items_size := ITEMS.size()
	_copy_menu_callables.resize(items_size)
	for i: int in items_size:
		popup.add_icon_item(_copy_menu_items_icons[i], ITEMS[i], i)
		_copy_menu_callables[i] = items_calls[i]

	_options_menu_popup = PopupMenu.new()
	_options_menu_popup.hide_on_checkable_item_selection = false
	_options_menu_popup.get_node(^"@MarginContainer@14/@ScrollContainer@15/@Control@16")\
		.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	const SUB_MENU_NAME := &"options"
	_options_menu_popup.name = SUB_MENU_NAME
	popup.add_child(_options_menu_popup)
	_options_menu_popup.id_pressed.connect(_on_options_menu_id_pressed)
	popup.add_submenu_item("Options", SUB_MENU_NAME, items_size)

	const OPTIONS := [ELAPSED_TIME, PAUSE_SPAN, &"Longest/Shortest"]
	var options_calls := [
		_copy_menu_toggle_elapsed_time,
		_copy_menu_toggle_pause_time,
		_copy_menu_toggle_shortest_longest,
	]
	var options_flags_values := CopyMenuFlags.values()
	var options_size := OPTIONS.size()
	_options_menu_callables.resize(options_size)
	for i: int in options_size:
		_options_menu_callables[i] = options_calls[i]

		_options_menu_popup.add_check_item(OPTIONS[i], i)
		if _copy_menu_options_mask & options_flags_values[i] != 0:
			_options_menu_popup.set_item_checked(i, true)

	
	if _stopwatch.has_started():
		_set_b_start_continue()

		var time_state := _stopwatch.get_time_state()
		_instantiate_stopwatch_entries_ui(time_state.resumed_times_size())

		_find_longest_shortest_times()

	_on_window_size_changed()

	_set_entry_tray_size_and_position_x.call_deferred()

	if _is_entry_tray_folded:
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel()\
			.tween_property(_c_icon_fold_tray, ^"rotation", 0.0, TRAY_DISAPPEAR_DUR)


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
	
	# Fix existing matched entries
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

	_set_entry_tray_visibility()
	_set_buttons_disabled(not _stopwatch.has_started())

	HOVER_TIP_FOLLOW.hide_hover_tip()


func undo_deleted_stopwatch_entry_ui() -> void:
	var time_state := _stopwatch.get_time_state()
	if not time_state.can_undo():
		return
	
	_set_entry_tray_visibility()
	
	var index := time_state.undo_deleted_entry()
	var new_entry := _instantiate_stopwatch_entry_ui(
		index, _stopwatch_tray_entries_ui.size() - index
	)
	
	var resumed_size := time_state.resumed_times_size()
	if index < resumed_size:
		new_entry.set_resume_time(
			Time.get_time_string_from_unix_time(time_state.get_resumed_time(index))
		)

	for i: int in range(index + 1, _stopwatch_tray_entries_ui.size()):
		_stopwatch_tray_entries_ui[i].set_pause_span(TEMPLATE_NUM_ENTRY % (i + 1))

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


func fix_stopwatch_tray_positioning() -> void:
	if not _vbc_entry_tray.visible or _entry_tray_tween.is_running():
		return

	await GLOBAL.tree.create_timer(.000001).timeout

	_set_entry_tray_size_and_position_x()

	if _is_entry_tray_folded:
		_vbc_entry_tray.position.y = _entry_tray_y_position(_vbc_stopwatch_and_buttons.position.y)
		return

	_vbc_stopwatch_and_buttons.position.y = _stopwatch_upper_position()
	_vbc_entry_tray.position.y = _entry_tray_y_position(_vbc_stopwatch_and_buttons.position.y)
	_vbc_entry_tray.size.y = _max_entry_tray_size_y(_vbc_entry_tray.position.y)


func load(save_dict: Dictionary) -> void:
	for key: String in SAVE_KEYS:
		self[key] = save_dict[key]


func save() -> Dictionary:
	var save_dict := {}
	for key: String in SAVE_KEYS:
		save_dict[key] = self[key]
	return save_dict


func _set_button_state(button: Button, state: bool) -> void:
	button.disabled = state
	button.mouse_default_cursor_shape = CURSOR_FORBIDDEN if state else CURSOR_POINTING_HAND


func _set_buttons_disabled(state: bool) -> void:
	_set_button_state(_b_reset, state)
	_set_button_state(_b_clipboard, state)


func _on_stopwatch_started() -> void:
	_set_buttons_disabled(false)


func _stopwatch_paused() -> void:
	_instantiate_stopwatch_entry_ui(_stopwatch_tray_entries_ui.size(), 0)

	_set_entry_tray_visibility()


func _stopwatch_resumed() -> void:
	var time_state = _stopwatch.get_time_state()
	var index := time_state.resumed_times_size() - 1
	_stopwatch_tray_entries_ui.back().set_resume_time(
		Time.get_time_string_from_unix_time(time_state.get_resumed_time(index))
	)

	if index < 1:
		return

	if index == 1:
		_find_longest_shortest_times()
	else:
		var pause_span := time_state.pause_span(index)
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
	_set_buttons_disabled(true)

	_b_start.button_pressed = false
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("start")

	_stopwatch.reset()

	for entry: StopwatchEntryUI in _stopwatch_tray_entries_ui:
		entry.queue_free()
	
	_stopwatch_tray_entries_ui.clear()

	_set_entry_tray_visibility()

	_longest_entry_index = 0
	_shortest_entry_index = 0


func _set_clipboard(to_copy: String, message: String) -> void:
	DisplayServer.clipboard_set(to_copy)

	_l_copied_time.text = "Copied!\n%s" % message

	if _pop_up_tween:
		_pop_up_tween.kill()

	_copied_pop_up.scale.y = 0.0
	_copied_pop_up.visible = true

	_pop_up_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_pop_up_tween.tween_property(_copied_pop_up, ^"scale:y", _pop_up_scale, .25)
	_pop_up_tween.tween_callback(func() -> void:
		_copied_pop_up.visible = false
	).set_delay(.66)


func _copy_elapsed_time_to_clipboard() -> void:
	var time := Global.seconds_to_time(_stopwatch.get_time_state().elapsed_time)
	_set_clipboard(time, time)


func _on_copy_menu_id_pressed(id: int) -> void:
	_copy_menu_callables[id].call()


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
		_copy_menu_options_mask & CopyMenuFlags.LONGEST_SHORTEST != 0 and resumed_size > 1
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
			(template_longest_shortest % TEMPLATE_NUM_ENTRY % pause_span_indexes[i])
				if show_longest_shortest else ""
		]
	
	if show_longest_shortest:
		entries_text[base_size + _longest_entry_index] = entries_text[base_size + _longest_entry_index].replace(
			template_longest_shortest % TEMPLATE_NUM_ENTRY % (resumed_size - 1), template_longest_shortest % "Longest"
		)
		entries_text[base_size + _shortest_entry_index] = entries_text[base_size + _shortest_entry_index].replace(
			template_longest_shortest % TEMPLATE_NUM_ENTRY % 0, template_longest_shortest % "Shortest"
		)

	_set_clipboard("\n".join(entries_text), message)


func _copy_menu_simple() -> void:
	_copy_menu_tray_entries(
		"Simple",
		PackedStringArray(),
		"#%s  %s%s  %s%s%s",
		"%s  ",
		"  %s",
		"  %s",
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


func _copy_menu_long() -> void:
	var entries_text := PackedStringArray(["".join(_build_copy_heading(
		"%s  |",
		"  %s  |",
		"  %s",
		"  %s  |",
		"  |  %s",
		"  |  %s"
	))])
	_copy_menu_tray_entries("Long", entries_text,
		"#%s          %s|     %s     |     %s%s%s",
		"|      %s       ",
		"        |    %s",
		"     |  %s" if _copy_menu_options_mask & CopyMenuFlags.PAUSE_SPANS != 0 else "        |  %s",
	)


func _copy_menu_csv() -> void:
	var entries_text := PackedStringArray(["".join(_build_copy_heading(
		"%s,",
		"%s,",
		"%s",
		"%s,",
		",%s",
		",%s",
	))])
	_copy_menu_tray_entries(
		"CSV",
		entries_text,
		"#%s,%s%s,%s%s%s",
		"%s,",
		",%s",
		",%s"
	)


func _copy_menu_markdown() -> void:
	var heading := _build_copy_heading("|%s", "|%s", "|%s|", "|%s", "%s|", "%s|")
	var heading_size := heading.size()
	heading.resize(heading_size * 2 + 1)
	heading[heading_size] = "\n"
	heading[heading_size + 1] = "|:-|"
	for i: int in heading_size - 2:
		heading[i + heading_size + 2] = ":-:|"
	
	heading[heading_size * 2] =\
		":-|" if (_copy_menu_options_mask & CopyMenuFlags.LONGEST_SHORTEST != 0) else ":-:|"

	_copy_menu_tray_entries(
		"MD Table",
		PackedStringArray(["".join(heading)]),
		"|#%s%s|%s|%s|%s%s",
		"|%s",
		"%s|",
		"%s|",
	)


func _on_options_menu_id_pressed(id: int) -> void:
	_options_menu_callables[id].call(id)


func _copy_menu_toggle_options(index: int, flag: int) -> void:
	var is_option_checked := _copy_menu_options_mask & flag != 0
	_options_menu_popup.set_item_checked(index, not is_option_checked)

	if is_option_checked:
		_copy_menu_options_mask = _copy_menu_options_mask & ~flag
	else:
		_copy_menu_options_mask = _copy_menu_options_mask | flag


func _copy_menu_toggle_elapsed_time(id: int) -> void:
	_copy_menu_toggle_options(id, CopyMenuFlags.ELAPSED_TIMES)


func _copy_menu_toggle_shortest_longest(id: int) -> void:
	_copy_menu_toggle_options(id, CopyMenuFlags.LONGEST_SHORTEST)


func _copy_menu_toggle_pause_time(id: int) -> void:
	_copy_menu_toggle_options(id, CopyMenuFlags.PAUSE_SPANS)


func _on_window_size_changed() -> void:
	# Scale text to fit size
	var scale_x := GLOBAL.window.size.x / float(GLOBAL.window.max_size.x)
	var win_height := GLOBAL.window.size.y
	var win_max_height := float(GLOBAL.window.max_size.y)
	var min_scale_y := (
		win_height + _vbc_stopwatch_and_buttons.pivot_offset.y - _stopwatch_and_buttons_separation
	) / win_max_height
	var s := minf(scale_x, maxf((win_height / win_max_height) * (min_scale_y * 3.0), min_scale_y))
	_vbc_stopwatch_and_buttons.scale = Vector2(s, s)

	# Slight scale s_copied
	_pop_up_scale = clampf(s * 1.025, .7, 1.0)
	_copied_pop_up.scale = Vector2(_pop_up_scale, _pop_up_scale)

	# Slight scale buttons
	var b_s := maxf(1.0, 1.75 - s)
	var b_scale = Vector2(b_s, b_s)
	_b_start.scale = b_scale
	_b_reset.scale = b_scale
	_b_clipboard.scale = b_scale

	if _stopwatch_tray_entries_ui.is_empty() or not _set_entry_tray_visibility():
		return

	_set_entry_tray_separation()

	_set_entry_tray_size_and_position_x()

	if _entry_tray_tween.is_running():
		return

	if _is_entry_tray_folded:
		_vbc_entry_tray.position.y = _entry_tray_y_position(_vbc_stopwatch_and_buttons.position.y)
		return

	_vbc_stopwatch_and_buttons.position.y = _stopwatch_upper_position()
	_vbc_entry_tray.position.y = _entry_tray_y_position(_vbc_stopwatch_and_buttons.position.y)

	_vbc_entry_tray.size.y = _max_entry_tray_size_y(_vbc_entry_tray.position.y)


func _on_stopwatch_entry_hovered(entry: StopwatchEntryUI) -> void:
	entry.modulate_animation(_hover_entry_colour)


func _on_stopwatch_entry_deleted(entry: StopwatchEntryUI) -> void:
	_delete_stopwatch_entry_ui(_stopwatch_tray_entries_ui.find(entry))


func _set_b_start_continue() -> void:
	_b_start.icon = _sprite_start
	_b_start.set_tip_name("continue")


func _stopwatch_upper_position() -> float:
	return (size.y - _vbc_stopwatch_and_buttons.size.y) * (
		.0 if GLOBAL.window.always_on_top else .25
	)


func _set_entry_tray_size_and_position_x() -> void:
	_vbc_entry_tray.size.x = GLOBAL.window.size.x * .9
	_vbc_entry_tray.position.x = (size.x - _vbc_entry_tray.size.x) * .5


func _set_entry_tray_separation() -> void:
	var h_separation = _get_h_separation_entry_tray()
	_hbc_tray_heading.add_theme_constant_override("separation", h_separation)
	for entry: StopwatchEntryUI in _stopwatch_tray_entries_ui:
		entry.set_separation(h_separation)


func _entry_tray_y_position(stopwatch_y_pos: float) -> float:
	return (
		stopwatch_y_pos
		+ _entry_tray_separation
		+ (_vbc_stopwatch_and_buttons.size.y * .5 * (
			_vbc_stopwatch_and_buttons.scale.y + _b_start.scale.y
		))
	)


func _max_entry_tray_size_y(entry_tray_y_position: float) -> float:
	return size.y - entry_tray_y_position - _entry_tray_separation


func _tray_stopwatch_animation(
	t: float,
	stopwatch_end_y_pos: float,
	tray_end_y_pos: float,
) -> void:
	_vbc_stopwatch_and_buttons.position.y = lerpf(
		(size.y - _vbc_stopwatch_and_buttons.size.y) * .5, stopwatch_end_y_pos, t
	)

	_vbc_entry_tray.size.y = lerpf(0.0, _max_entry_tray_size_y(tray_end_y_pos), t)


func _tray_animation(t: float, to_y_pos: float) -> void:
	_vbc_entry_tray.position.y = lerpf(
		GLOBAL.window.size.y + (_entry_tray_heading_height * 2.0), to_y_pos, t
	)
	_vbc_entry_tray.modulate.a = t


func _tray_disappear_unfolded_animation(t: float) -> void:
	var stopwatch_upper_pos := _stopwatch_upper_position()
	var tray_end_y_pos := _entry_tray_y_position(stopwatch_upper_pos)
	_tray_stopwatch_animation(t, stopwatch_upper_pos, tray_end_y_pos)
	_tray_animation(t, tray_end_y_pos)


func _tray_disappear_folded_animation(t: float) -> void:
	_tray_animation(t, _entry_tray_y_position((size.y - _vbc_stopwatch_and_buttons.size.y) * .5))


func _set_entry_tray_visibility() -> bool:
	var is_vis := (
		not _stopwatch_tray_entries_ui.is_empty()
		and GLOBAL.window.size.x > _width_for_min_h_separation
		and GLOBAL.window.size.y > (
			_window_height_to_disappear_tray
			+_stopwatch_upper_position() * .5
			+ _vbc_stopwatch_and_buttons.size.y * .5 * (
				_vbc_stopwatch_and_buttons.scale.y + _b_start.scale.y
			)
		)
	)
	if is_vis == _is_entry_tray_visible:
		return is_vis

	_is_entry_tray_visible = is_vis

	if _entry_tray_tween:
		_entry_tray_tween.kill()

	var animation := _tray_disappear_folded_animation if _is_entry_tray_folded\
		else _tray_disappear_unfolded_animation
	_entry_tray_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	if is_vis:
		_set_entry_tray_separation()
		_set_entry_tray_size_and_position_x()

		_vbc_entry_tray.visible = true
		_entry_tray_tween.tween_method(
			animation,
			_vbc_entry_tray.modulate.a,
			1.0,
			TRAY_DISAPPEAR_DUR - (TRAY_DISAPPEAR_DUR * _vbc_entry_tray.modulate.a),
		)
	else:
		_entry_tray_tween.tween_method(
			animation,
			_vbc_entry_tray.modulate.a,
			0.0,
			TRAY_DISAPPEAR_DUR * _vbc_entry_tray.modulate.a,
		)

		_entry_tray_tween.tween_callback(func() -> void:
			_vbc_entry_tray.visible = false
		)

	return is_vis


func _fold_tray_animation(t: float) -> void:
	var stopwatch_end_y_pos := _stopwatch_upper_position()
	_tray_stopwatch_animation(t, stopwatch_end_y_pos, _entry_tray_y_position(stopwatch_end_y_pos))
	_vbc_entry_tray.position.y = _entry_tray_y_position(_vbc_stopwatch_and_buttons.position.y)
	_c_icon_fold_tray.rotation = lerp_angle(0.0, deg_to_rad(90.0), t)


func _toggle_fold_tray() -> void:
	if not _is_entry_tray_visible:
		return

	_is_entry_tray_folded = not _is_entry_tray_folded

	if _entry_tray_tween:
		_entry_tray_tween.kill()

	_entry_tray_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	var inverse_t := inverse_lerp(0.0, deg_to_rad(90.0), _c_icon_fold_tray.rotation)
	const DUR := .4
	if _is_entry_tray_folded:
		_b_toggle_fold_tray.set_tip_name("unfold tray")
		_entry_tray_tween.tween_method(_fold_tray_animation, inverse_t, 0.0, DUR * inverse_t)
	else:
		_b_toggle_fold_tray.set_tip_name("fold tray")
		_entry_tray_tween.tween_method(_fold_tray_animation, inverse_t, 1.0, DUR - (DUR * inverse_t))


func _get_h_separation_entry_tray() -> int:
	return int(remap(
		GLOBAL.window.size.x,
		GLOBAL.window.max_size.x,
		_width_for_min_h_separation,
		_tray_h_separation_range.x,
		_tray_h_separation_range.y,
	))


func _instantiate_stopwatch_entry_ui(
	insert_at: int,
	move_to: int,
	separation: int = _get_h_separation_entry_tray(),
) -> StopwatchEntryUI:
	var new_entry: StopwatchEntryUI = _scene_stopwatch_entry_ui.instantiate()
	_stopwatch_tray_entries_ui.insert(insert_at, new_entry)

	var time_state := _stopwatch.get_time_state()
	new_entry.init(
		TEMPLATE_NUM_ENTRY % (insert_at + 1),
		Time.get_time_string_from_unix_time(time_state.get_paused_time(insert_at)),
		Global.seconds_to_time(time_state.get_elapsed_time(insert_at)),
		_on_stopwatch_entry_hovered,
		_on_stopwatch_entry_deleted,
		separation,
	)

	_vbc_entry_container.add_child(new_entry)
	_vbc_entry_container.move_child(new_entry, move_to)

	return new_entry


func _instantiate_stopwatch_entries_ui(amount: int, index_offset: int = 0) -> void:
	var time_state := _stopwatch.get_time_state()
	var separation := _get_h_separation_entry_tray()
	for i: int in amount:
		var index := index_offset + i
		_instantiate_stopwatch_entry_ui(i + index_offset, 0, separation)\
			.set_resume_time(Time.get_time_string_from_unix_time(time_state.get_resumed_time(index)))
	
	if (amount + index_offset) < time_state.paused_times_size():
		_instantiate_stopwatch_entry_ui(amount + index_offset, 0, separation)


func _delete_stopwatch_entry_ui(index: int) -> void:
	_stopwatch_tray_entries_ui[index].set_colour(_hover_entry_colour)
	_stopwatch_tray_entries_ui.remove_at(index)

	var time_state := _stopwatch.get_time_state()
	time_state.delete_entry(index)

	_set_entry_tray_visibility()

	for i: int in range(index, _stopwatch_tray_entries_ui.size()):
		_stopwatch_tray_entries_ui[i].replace_pause_num(
			TEMPLATE_NUM_ENTRY % (i + 2), TEMPLATE_NUM_ENTRY % (i + 1)
		)

	var was_longest := index == _longest_entry_index
	var was_shortest := index == _shortest_entry_index

	if index < _shortest_entry_index:
		_shortest_entry_index -= 1

	if index < _longest_entry_index:
		_longest_entry_index -= 1

	var entries_size := time_state.resumed_times_size()
	if entries_size < 2:
		if entries_size == 0 and time_state.paused_times_size() == 0:
			_vbc_entry_tray.hide()
		elif was_longest:
			_clear_entry_suffix(_shortest_entry_index)
		elif was_shortest:
			_clear_entry_suffix(_longest_entry_index)

		return
	
	if was_longest:
		var longest_span := -Global.FLOAT_MAX
		_longest_entry_index = 0

		for i: int in entries_size:
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
	_stopwatch_tray_entries_ui[index].set_pause_span(TEMPLATE_NUM_ENTRY % (index + 1))


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
