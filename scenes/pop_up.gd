class_name PopUp extends ColorRect


@export var l_text: Label
@export var label_padding := Vector2(12.0, 8.0)
@export var dent: Control
@export var _animation_duration := .25

var font: Font
var font_size : int

var _tween: Tween


func _ready() -> void:
	font = l_text.get_theme_font("font")
	font_size = l_text.get_theme_font_size("font_size")


func pop_up(c: Control, text: String) -> void:
	l_text.text = text
	var s: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

	size = s + label_padding
	pivot_offset = s * .5

	global_position = Vector2(
		c.global_position.x + (c.size.x - size.x) * .5,
		c.global_position.y + c.size.y + dent.size.y + label_padding.y)
	
	visible = true
	scale = Vector2(.75, .75)
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_ease(_tween.EASE_IN).set_trans(_tween.TRANS_ELASTIC)
	_tween.tween_property(self, "scale", Vector2(1.0, 1.0), _animation_duration)


func un_pop() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_ease(_tween.EASE_OUT).set_trans(_tween.TRANS_ELASTIC)
	_tween.tween_property(self, "scale", Vector2(.5, .5), _animation_duration)
	await _tween.finished

	visible = false
