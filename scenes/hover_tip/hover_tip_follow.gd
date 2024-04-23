class_name HoverTipFollow extends HoverTip


func _ready() -> void:
	super()
	set_process(false)


func _process(_delta: float) -> void:
	# FIXME I can get outside window
	position = get_global_mouse_position()


func show_hover_tip(text: String) -> void:
	_set_text(text)
	set_process(true)


func hide_hover_tip() -> void:
	if not visible:
		_delay_to_appear.paused = true
	else:
		visible = false
	
	set_process(false)
