class_name PopUp extends Panel


@export var _label_padding := Vector2(10.0, 4.0)
@export var _animation_duration := .15

var _font: Font
var _font_size : int

var _tween: Tween

@onready var _l_text: Label = %l_text
@onready var _dent: Control = %dent
@onready var _delay_to_appear: Timer = %delay_to_appear

@onready var window := get_window()


func _ready() -> void:
	_delay_to_appear.timeout.connect(_pop_up_animation)

	_font = _l_text.get_theme_font("_font")
	_font_size = _l_text.get_theme_font_size("_font_size")


func pop_up(c: Control, text: String) -> void:
	if _tween:
		_tween.kill()
		visible = false
	
	_l_text.text = text

	var s := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)
	size = s + _label_padding
	pivot_offset = size * .5

	var c_scale := c.get_global_transform().get_scale()
	var new_x := c.global_position.x + (c.size.x * c_scale.x - size.x) * .5
	var right := new_x + size.x
	var out_x := 0.0
	# This is only checking right checking left wouldn't be to difficult but it's unnecessary due to the current layout
	if window.size.x <= right:
		out_x = window.size.x - right - _label_padding.x
		new_x += out_x

	var new_y := c.global_position.y + c.size.y * c_scale.y + _label_padding.y - _dent.position.y
	var bot := new_y + size.y
	if window.size.y <= bot:
		new_y += window.size.y - bot - _label_padding.y
	
	global_position = Vector2(new_x, new_y)

	_dent.position.x = pivot_offset.x - _dent.pivot_offset.x - out_x

	_delay_to_appear.paused = false
	_delay_to_appear.start(_delay_to_appear.wait_time)


func un_pop() -> void:
	if not visible:
		_delay_to_appear.paused = true
		return
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2(.5, .5), _animation_duration)
	await _tween.finished

	visible = false


func _pop_up_animation() -> void:
	visible = true
	scale = Vector2(.75, .75)
	
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), _animation_duration)
