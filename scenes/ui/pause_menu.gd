extends CanvasLayer

signal resumed
signal went_to_main_menu

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Semi-transparent backdrop
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var fade := overlay.create_tween()
	fade.tween_property(overlay, "color:a", 0.65, 0.2)

	# Panel
	var panel := PanelContainer.new()
	panel.size = Vector2(360, 320)
	panel.position = Vector2(960 - 180, 1080 / 2.0 - 160)
	panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.10)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.border_color = Color(0.5, 0.4, 0.75)
	style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	vbox.add_child(title)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.4, 0.3, 0.6, 0.5)
	sep_style.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	vbox.add_child(Control.new())  # Spacer

	# Buttons
	for entry in [["FORTSETZEN", "_on_resume"], ["EINSTELLUNGEN", "_on_settings"], ["HAUPTMENÜ", "_on_main_menu"]]:
		var btn := Button.new()
		btn.text = entry[0]
		btn.custom_minimum_size = Vector2(260, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_apply_btn_style(btn)
		btn.pressed.connect(Callable(self, entry[1]))
		vbox.add_child(btn)

	# Fade in panel
	var ptw := create_tween()
	ptw.tween_interval(0.1)
	ptw.tween_property(panel, "modulate:a", 1.0, 0.2)

func _apply_btn_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.10, 0.34)
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_width_left = 1; s.border_width_right = 1
	s.border_color = Color(0.5, 0.32, 0.8)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.28, 0.16, 0.50)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 1.0))
	btn.add_theme_font_size_override("font_size", 18)

func _on_resume() -> void:
	SFX.play("button_click", 0.0)
	get_tree().paused = false
	emit_signal("resumed")
	queue_free()

func _on_settings() -> void:
	SFX.play("button_click", 0.0)
	var settings := CanvasLayer.new()
	settings.set_script(preload("res://scenes/ui/settings_menu.gd"))
	get_tree().root.add_child(settings)
	settings.setup(self)

func _on_main_menu() -> void:
	SFX.play("button_click", 0.0)
	get_tree().paused = false

	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.z_index = 100
	add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	emit_signal("went_to_main_menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
