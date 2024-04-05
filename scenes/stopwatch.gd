class_name StopWatch
extends VBoxContainer


@export var _time_text_template := "%02d:%02d:%02d.[font_size=48]%d[/font_size]"

var elapsed_time := 0.0

@onready var _l_time: RichTextLabel = %l_time


func _process(delta: float) -> void:
    elapsed_time += delta

    _l_time.text = _time_text_template % [
            (elapsed_time / 3600.0),
            (fmod(elapsed_time, 3600.0) / 60.0),
            (fmod(elapsed_time, 60.0)),
            (fmod(elapsed_time, 1) * 100.0)
    ]
