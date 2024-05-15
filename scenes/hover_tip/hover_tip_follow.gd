class_name HoverTipFollow extends HoverTip


func _input(event: InputEvent) -> void:
	var m_event := event as InputEventMouse
	if not m_event:
		return

	var new_pos := m_event.position - size

	# We are only correcting the position if we go out to the left
	if new_pos.x < _label_padding.x * .5:
		new_pos.x = _label_padding.x * .5

	position = new_pos


func show_hover_tip(text: String) -> void:
	_set_text(text)
	set_process_input(true)


func hide_hover_tip() -> void:
	if not visible:
		_delay_to_appear.paused = true
	else:
		visible = false
	
	set_process_input(false)
