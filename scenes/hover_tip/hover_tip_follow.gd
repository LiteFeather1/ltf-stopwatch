class_name HoverTipFollow extends HoverTip


func _ready() -> void:
	super()
	set_process(false)


func _process(_delta: float) -> void:
	var new_pos := get_global_mouse_position() - size

	# We are only correcting the position if we go out to the left
	if new_pos.x < _label_padding.x:
		new_pos.x -= new_pos.x + _label_padding.x

	position = new_pos


func show_hover_tip(text: String) -> void:
	_set_text(text)
	set_process(true)


func hide_hover_tip() -> void:
	if not visible:
		_delay_to_appear.paused = true
	else:
		visible = false
	
	set_process(false)
