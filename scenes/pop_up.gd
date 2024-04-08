class_name PopUp extends ColorRect


@export var l_text: Label
@export var label_padding := Vector2(10.0, 5.0)
@export var dent: Control
@export var _animation_duration := .25

var _tween: Tween

func pop_up(c: Control, text: String) -> void:
	l_text.text = text

	size = l_text.size + label_padding
	pivot_offset = size * .5

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
