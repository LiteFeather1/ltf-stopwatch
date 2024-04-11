class_name ButtonPopUp extends Button


@export var _pop_up_name: String = "name"


func set_pop_up_name(pop_up_name: String) -> void:
	_pop_up_name = pop_up_name


func _ready() -> void:
	mouse_entered.connect(show_pop_up)
	mouse_exited.connect(hide_pop_up)


func _pressed() -> void:
	mouse_exited.emit()
	if not disabled:
		mouse_entered.emit()


func show_pop_up() -> void:
	if not disabled:
		AL_PopUp.pop_up(self, _pop_up_name)


func hide_pop_up() -> void:
	AL_PopUp.un_pop()
