class_name ButtonPopUp extends Button


@export var pop_up_name: String = "name"


func _ready() -> void:
	mouse_entered.connect(show_pop_up)
	mouse_exited.connect(hide_pop_up)


func show_pop_up() -> void:
	if not disabled:
		AL_PopUp.pop_up(self, pop_up_name)


func hide_pop_up() -> void:
	if not disabled:
		AL_PopUp.un_pop()
