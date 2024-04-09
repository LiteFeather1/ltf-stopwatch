class_name PopUp extends ColorRect


@export var _label_padding := Vector2(8.0, 4.0)
@export var _animation_duration := .15

var _font: Font
var _font_size : int

var _tween: Tween

@onready var _l_text: Label = %l_text
@onready var _dent: Control = %dent
@onready var _delay_to_appear: Timer = %delay_to_appear


func _ready() -> void:
	_delay_to_appear.timeout.connect(_pop_up_animation)

	_font = _l_text.get_theme_font("_font")
	_font_size = _l_text.get_theme_font_size("_font_size")


func pop_up(c: Control, text: String) -> void:
	if _tween:
		_tween.kill()
		visible = false
	
	_l_text.text = text
	var s: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size)

	size = s + _label_padding
	pivot_offset = s * .5

	var c_scale := c.get_global_transform().get_scale()
	global_position = Vector2(
		c.global_position.x + ((c.size.x * c_scale.x) - size.x) * .5,
		c.global_position.y + (c.size.y * c_scale.y) + _dent.size.y + _label_padding.y * .5)
	
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
