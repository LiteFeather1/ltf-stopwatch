class_name Chrome extends HBoxContainer

@export_category("Buttons")
@export var b_close: Button
@export var b_pin: Button

@export_category("Win settings")
@export var window_margin := Vector2i(-32, 32)

var dragging: bool
var start_drag_pos: Vector2

var previous_window_size: Vector2i
var previous_window_position: Vector2i

@onready var window: Window = get_window()


func _ready() -> void:
	%l_name.text = ProjectSettings.get_setting("application/config/name")


func _process(_delta: float) -> void:
	if not dragging:
		return
	
	window.position += Vector2i(get_global_mouse_position() - start_drag_pos)


func _on_chrome_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == 1: # Left mouse click
		dragging = not dragging
		start_drag_pos = get_global_mouse_position()


func _close_window() -> void:
	get_tree().quit()


func _minimise_window() -> void:
	window.mode = Window.MODE_MINIMIZED


func _toggle_always_on_top(pinning: bool) -> void:
	if pinning:
		b_pin.text = "nP"

		previous_window_position = window.position

		previous_window_size = window.size
		window.size = window.min_size

		var win_id := window.current_screen
		var right := DisplayServer.screen_get_position(win_id).x\
				+ DisplayServer.screen_get_size(win_id).x\
				- window.size.x\
				+ window_margin.x
		var top := window_margin.y
		window.position = Vector2i(right, top)
	else:
		b_pin.text = "P"

		window.size = previous_window_size
		window.position = previous_window_position
	
	b_close.visible = not pinning
	window.always_on_top = pinning
