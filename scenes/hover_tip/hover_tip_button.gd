class_name HoverTipButton extends HoverTip


const TEMPLATE_SHORTCUT := "%s\n%s"

const PADDING := 2.0

@export var _animation_duration := .15

@export var _dent: Control

var _simple_text_size: int
var _shortcut_text: String

var _tween: Tween


func _ready() -> void:
	super()

	set_process_unhandled_key_input(false)


func _unhandled_key_input(event: InputEvent) -> void:
	var old_size := size
	if event.is_action_pressed("ctrl"):
		_set_text(TEMPLATE_SHORTCUT % [_l_text.text, _shortcut_text])
		old_size.y += (
			((_dent.size.y * 2.0) + (PADDING * 1.5))
			* (1.0 if (_dent.anchor_top < 1.0) else -1.0)
		)
	elif event.is_action_released("ctrl"):
		_set_text(_l_text.text.substr(0, _simple_text_size))
		old_size.y -= (
			((_dent.size.y * 2.0) + (PADDING * 1.5))
			* (1.0 if _dent.anchor_top < 1.0 else -1.0)
		)
	
	position -= (size - old_size) * .5


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

	if GLOBAL.window.size.x <= right:
		out_x = GLOBAL.window.size.x - right - _label_padding.x
		new_x += out_x

	var new_y := c.global_position.y + (c.size.y * c_scale.y) + _dent.size.y + PADDING
	if GLOBAL.window.size.y <= new_y + size.y:
		new_y = c.global_position.y - size.y - _dent.size.y - PADDING
		_dent.anchor_top = 1.0
		_dent.anchor_bottom = 1.0
	else:
		_dent.anchor_top = 0.0
		_dent.anchor_bottom = 0.0

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
	_tween.tween_property(self, ^"scale", Vector2(.5, .5), _animation_duration)
	_tween.tween_callback(func() -> void:
		visible = false
	)


func _show() -> void:
	super()
	scale = Vector2(.75, .75)
	
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween.tween_property(self, ^"scale", Vector2(1.0, 1.0), _animation_duration)
