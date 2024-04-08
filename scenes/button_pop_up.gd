class_name ButtonPopUp extends ColorRect


@export var l_text: Label
@export var label_padding := Vector2(10.0, 5.0)
@export var dent: Control


func pop_up(c: Control, text: String) -> void:
	visible = true

	l_text.text = text

	size = l_text.size + label_padding
	pivot_offset = size * .5

	global_position = Vector2(
		c.global_position.x + (c.size.x - size.x) * .5,
		c.global_position.y + c.size.y + dent.size.y + label_padding.y)
	
	var t := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	scale = Vector2(.75, .75)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), .5)


