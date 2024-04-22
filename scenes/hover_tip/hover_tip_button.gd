class_name HoverTipButton extends HoverTip


@export var _animation_duration := .15

@export var _dent: Control

var _tween: Tween


func show_hover_tip(c: Control, text: String) -> void:
	if _tween:
		_tween.kill()
		visible = false
	
	_set_text(text)

	pivot_offset = size * .5

	var c_scale := c.get_global_transform().get_scale()
	var new_x := c.global_position.x + (c.size.x * c_scale.x - size.x) * .5
	var right := new_x + size.x
	var out_x := 0.0
	# This is only checking right checking left wouldn't be to difficult 
	# but it's unnecessary due to the current layout
	if Global.window.size.x <= right:
		out_x = Global.window.size.x - right - _label_padding.x
		new_x += out_x

	var new_y := c.global_position.y + c.size.y * c_scale.y + _label_padding.y - _dent.position.y
	var bot := new_y + size.y
	if Global.window.size.y <= bot:
		new_y += Global.window.size.y - bot - _label_padding.y
	
	global_position = Vector2(new_x, new_y)

	_dent.position.x = pivot_offset.x - _dent.pivot_offset.x - out_x


func hide_hover_tip() -> void:
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
