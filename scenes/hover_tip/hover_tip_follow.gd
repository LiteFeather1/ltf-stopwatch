class_name HoverTipFollow extends HoverTip


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
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
