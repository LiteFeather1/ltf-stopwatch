class_name HoverTipButton extends HoverTip


const TEMPLATE_SHORTCUT := "%s\n%s"

@export var _animation_duration := .15

@export var _dent: Control

var _simple_text_size: int
var _shortcut_text: String

var _tween: Tween


func _ready() -> void:
	super()

	set_process_unhandled_key_input(false)


func _unhandled_key_input(event: InputEvent) -> void:
	var old_size_x := size.x
	if event.is_action_pressed("ctrl"):
		_set_text(TEMPLATE_SHORTCUT % [_l_text.text, _shortcut_text])
	elif event.is_action_released("ctrl"):
		_set_text(_l_text.text.substr(0, _simple_text_size))
	
	position.x -= (size.x - old_size_x) * .5


func show_hover_tip(c: Control, text: String, shortcut_text := "") -> void:
	if _tween:
		_tween.kill()
		visible = false

	_simple_text_size = text.length()
	if Input.is_action_pressed("ctrl"):
		_set_text(TEMPLATE_SHORTCUT % [text, shortcut_text])
	else:
		_set_text(text)

	_shortcut_text = shortcut_text

	pivot_offset = size * .5

	var c_scale := c.get_global_transform().get_scale()
	var new_x := c.global_position.x + (c.size.x * c_scale.x - size.x) * .5
	var right := new_x + size.x
	var out_x := 0.0

	# This is only checkign right side. Checking left wouldn't be too difficult
	# but it's not necessary due to the current layout of buttons
	if GLOBAL.window.size.x <= right:
		out_x = GLOBAL.window.size.x - right - _label_padding.x
		new_x += out_x

	var new_y := c.global_position.y + c.size.y * c_scale.y - _dent.position.y + _dent.size.y * .5
	var bot := new_y + size.y
	if GLOBAL.window.size.y <= bot:
		new_y += GLOBAL.window.size.y - bot - _label_padding.y

	position = Vector2(new_x, new_y)

	_dent.position.x = pivot_offset.x - _dent.pivot_offset.x - out_x

	set_process_unhandled_key_input(true)


func hide_hover_tip() -> void:
	set_process_unhandled_key_input(false)

	if not visible:
		_delay_to_appear.paused = true
		return
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2(.5, .5), _animation_duration)
	_tween.tween_callback(func() -> void:
		visible = false
	)


func _show() -> void:
	super()
	scale = Vector2(.75, .75)
	
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), _animation_duration)
