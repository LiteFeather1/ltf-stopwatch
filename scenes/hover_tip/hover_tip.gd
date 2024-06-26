class_name HoverTip extends Panel


@export var _label_padding := Vector2(12.0, 8.0)
@export var _l_text: Label
@export var _delay_to_appear: Timer

var _font: Font
var _font_size: int


func _ready() -> void:
	_delay_to_appear.timeout.connect(_show)

	_font = _l_text.get_theme_font("font")
	_font_size = _l_text.get_theme_font_size("font_size")


func _set_text(text: String) -> void:
	_l_text.text = text

	size = (
		_label_padding
		+ _font.get_multiline_string_size(text, _l_text.horizontal_alignment, -1, _font_size)
	)
	_delay_to_appear.paused = false
	_delay_to_appear.start(_delay_to_appear.wait_time)


func _show() -> void:
	visible = true
