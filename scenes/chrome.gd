class_name Chrome extends HBoxContainer

@export var b_close: Button
@export var b_pin: Button

@export var move_window_smoothing_factor := .99

var dragging: bool
var start_drag_pos: Vector2
var smoothed_mouse_pos: Vector2

var previous_window_size: Vector2

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


func _toggle_always_on_top(pinning: bool) -> void:
	if pinning:
		b_pin.text = "nP"

		previous_window_size = window.size
		window.size = window.min_size
		var win_id := window.current_screen
		var right := DisplayServer.screen_get_position(win_id).x\
				+ DisplayServer.screen_get_size(win_id).x\
				- window.size.x
		var top := 0
		window.position = Vector2i(right, top)
	else:
		b_pin.text = "P"

		window.size = previous_window_size
	
	b_close.visible = not pinning
	window.always_on_top = pinning
