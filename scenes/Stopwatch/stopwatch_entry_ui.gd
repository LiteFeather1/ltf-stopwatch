class_name StopwatchEntryUI extends HBoxContainer


signal hovered(instance: StopwatchEntryUI)
signal deleted(instance: StopwatchEntryUI)


@export var _l_pause_span: Label
@export var _l_pause_time: Label
@export var _l_resume_time: Label

var _hover_message: String

var _is_mouse_inside := false

var _tween: Tween


func init(
	span: String,
	pause_time: String,
	hover_message: String,
	on_hovered: Callable,
	on_deleted: Callable,
	separation: int,
) -> void:
	_l_pause_span.text = span
	_l_pause_time.text = pause_time
	_hover_message = hover_message
	hovered.connect(on_hovered)
	deleted.connect(on_deleted)
	add_theme_constant_override("separation", separation)


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func _on_mouse_entered() -> void:
	_is_mouse_inside = true
	AL_HoverTipFollow.show_hover_tip(_hover_message)
	hovered.emit(self)


func _on_mouse_exited() -> void:
	_is_mouse_inside = false
	AL_HoverTipFollow.hide_hover_tip()

	if modulate == Color.WHITE:
		_tween.kill()
	else:
		modulate_animation(Color.WHITE, .25, .0)


func _on_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event\
			and mb_event.button_index == MOUSE_BUTTON_LEFT\
			and mb_event.is_released()\
			and _is_mouse_inside:
		deleted.emit(self)

		delete_routine()


func set_pause_span(text: String) -> void:
	_l_pause_span.text = text


func replace_pause_num(from: String, to: String) -> void:
	_l_pause_span.text = _l_pause_span.text.replace(from, to)


func set_times(
	paused_time: String,
	resumed_time: String,
	hover_message: String,
) -> void:
	_l_pause_time.text = paused_time
	_l_resume_time.text = resumed_time
	_hover_message = hover_message


func set_resume_time(time: String) -> void:
	_l_resume_time.text = time


func delete_routine() -> void:
	mouse_entered.disconnect(_on_mouse_entered)
	mouse_exited.disconnect(_on_mouse_exited)
	gui_input.disconnect(_on_gui_input)

	AL_HoverTipFollow.hide_hover_tip()

	if _tween:
		_tween.kill()

	var dir := 1.0 if randf() > .5 else -1.0
	var offset := randf_range(48.0, 64.0) * dir
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		self, "position:x",
		position.x + offset,
		randf_range(.15, .2),
	)
	tween.tween_property(
		self, "position:x",
		position.x -offset + size.x * -dir,
		randf_range(.175, .25),
	)
	
	await tween.finished

	queue_free()


func modulate_animation(colour: Color, duration: float = .4, interval = .33) -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(interval)
	_tween.tween_property(self, "modulate", colour, duration)
