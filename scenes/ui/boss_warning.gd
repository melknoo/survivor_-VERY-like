extends CanvasLayer

signal warning_done

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Letterbox strips
	for data in [
		[Vector2(0.0, 0.0), Vector2(1920.0, 80.0)],
		[Vector2(0.0, 1000.0), Vector2(1920.0, 80.0)],
	]:
		var strip := ColorRect.new()
		strip.position = data[0]
		strip.size = data[1]
		strip.color = Color(0.0, 0.0, 0.0, 0.0)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(strip)
		var tw := strip.create_tween()
		tw.tween_property(strip, "color:a", 0.55, 0.3)

	# Warning text
	var label := Label.new()
	label.text = "⚠  GEFAHR  ⚠"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(1920.0, 200.0)
	label.position = Vector2(0.0, 440.0)
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(0.95, 0.1, 0.1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

	# Fade in label
	var ltw := label.create_tween()
	ltw.tween_property(label, "modulate:a", 1.0, 0.2)

	# Pulse the label scale
	var pulse := label.create_tween().set_loops()
	pulse.tween_property(label, "scale", Vector2(1.06, 1.06), 0.25).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(label, "scale", Vector2(0.96, 0.96), 0.25).set_trans(Tween.TRANS_SINE)

	# Dismiss after 2 seconds and emit warning_done
	var timer := get_tree().create_timer(2.0, true, false, true)
	timer.timeout.connect(_dismiss)

	SFX.play("lightning_strike", 0.0, -2.0)

func _dismiss() -> void:
	var tw := create_tween().set_parallel(true)
	for child in get_children():
		tw.tween_property(child, "modulate:a", 0.0, 0.3)
	await tw.finished
	emit_signal("warning_done")
	queue_free()
