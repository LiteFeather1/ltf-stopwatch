class_name ButtonHoverTip extends Button


@export var _tip_name: String = "tip"


func set_tip_name(tip_name: String) -> void:
	_tip_name = tip_name


func _ready() -> void:
	mouse_entered.connect(_show_hover_tip)
	mouse_exited.connect(_hide_hover_tip)
	pressed.connect(_hide_hover_tip)


func _pressed() -> void:
	mouse_exited.emit()
	if not disabled:
		mouse_entered.emit()


func _show_hover_tip() -> void:
	if not disabled:
		HOVER_TIP_BUTTON.show_hover_tip(self, _tip_name, shortcut.get_as_text())


func _hide_hover_tip() -> void:
	if not disabled:
		HOVER_TIP_BUTTON.hide_hover_tip()
