class_name ButtonHoverTip extends Button


@export var _tip_name: String = "tip"


func set_tip_name(tip_name: String) -> void:
	_tip_name = tip_name


func _ready() -> void:
	mouse_entered.connect(show_hover_tip)
	mouse_exited.connect(hide_hover_tip)


func _pressed() -> void:
	mouse_exited.emit()
	if not disabled:
		mouse_entered.emit()


func show_hover_tip() -> void:
	if not disabled:
		AL_PopUp.show_hover_tip(self, _tip_name)


func hide_hover_tip() -> void:
	AL_PopUp.hide_hover_tip()
