extends Node2D

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.1))
	_label.add_theme_font_size_override("font_size", 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	z_index = 100

func setup(amount: int) -> void:
	_label.text = str(amount)

	# Pop in scale
	scale = Vector2(1.4, 1.4)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.parallel().tween_property(self, "position:y", position.y - 35.0, 0.7)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tween.tween_callback(queue_free)
