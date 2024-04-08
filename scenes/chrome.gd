class_name Chrome extends HBoxContainer

@export var b_close: Button
@export var b_pin: Button

@export var move_window_smoothing_factor := .99

var dragging: bool
var start_drag_pos: Vector2
var smoothed_mouse_pos: Vector2


@onready var window: Window = get_window()


func _process(_delta: float) -> void:
	if not dragging:
		return
	
	smoothed_mouse_pos = smoothed_mouse_pos.lerp(
			window.get_mouse_position(), move_window_smoothing_factor)
	window.position += Vector2i(smoothed_mouse_pos - start_drag_pos)


func _on_chrome_gui_input(event: InputEvent) -> void:
	var mb_event := event as InputEventMouseButton
	if mb_event and mb_event.button_index == 1: # Left mouse click
		dragging = not dragging
		var m_pos := window.get_mouse_position()
		start_drag_pos = m_pos
		smoothed_mouse_pos = m_pos


func _close_window() -> void:
	get_tree().quit()


func _minimise_window() -> void:
	window.mode = Window.MODE_MINIMIZED


func _toggle_always_on_top(state: bool) -> void:
	b_pin.text = "nP" if state else "P"
	b_close.visible = not state
	window.always_on_top = state
