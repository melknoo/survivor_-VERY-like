extends CanvasLayer

signal closed

# Optional: pass the pause_menu reference so it can re-show itself after close
var _return_node: Node = null

func setup(return_node: Node) -> void:
	_return_node = return_node

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Backdrop
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var fade := overlay.create_tween()
	fade.tween_property(overlay, "color:a", 0.75, 0.25)

	# Panel
	var panel := PanelContainer.new()
	panel.size = Vector2(500, 380)
	panel.position = Vector2(960 - 250, 1080 / 2.0 - 190)
	panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.10)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.55, 0.45, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "EINSTELLUNGEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	vbox.add_child(title)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.4, 0.3, 0.6, 0.5)
	sep_style.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Music volume
	vbox.add_child(_make_slider_row("Musik", Settings.music_volume, func(v: float) -> void:
		Settings.music_volume = int(v)
		Settings.apply_to_buses()
	))

	# SFX volume
	vbox.add_child(_make_slider_row("Sound-Effekte", Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = int(v)
		Settings.apply_to_buses()
	))

	# Screenshake toggle
	vbox.add_child(_make_checkbox_row("Kamera-Shake", Settings.screenshake, func(v: bool) -> void:
		Settings.screenshake = v
	))

	vbox.add_child(Control.new())  # Spacer

	# Close button
	var close_btn := Button.new()
	close_btn.text = "SCHLIESSEN"
	close_btn.custom_minimum_size = Vector2(200, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_btn_style(close_btn)
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)

	# Slide panel in
	var ptw := create_tween()
	ptw.tween_interval(0.1)
	ptw.tween_property(panel, "modulate:a", 1.0, 0.2)

func _make_slider_row(label_text: String, init_value: int, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.9))
	lbl.add_theme_font_size_override("font_size", 17)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = init_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = str(init_value)
	val_lbl.custom_minimum_size = Vector2(36, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	val_lbl.add_theme_font_size_override("font_size", 17)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void: val_lbl.text = str(int(v)))

	return row

func _make_checkbox_row(label_text: String, init_value: bool, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.9))
	lbl.add_theme_font_size_override("font_size", 17)
	row.add_child(lbl)

	var check := CheckButton.new()
	check.button_pressed = init_value
	check.toggled.connect(callback)
	row.add_child(check)

	return row

func _apply_btn_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.12, 0.38)
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_width_left = 1; s.border_width_right = 1
	s.border_color = Color(0.55, 0.35, 0.85)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.32, 0.18, 0.55)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 1.0))
	btn.add_theme_font_size_override("font_size", 16)

func _on_close() -> void:
	SFX.play("button_click", 0.0)
	Settings.save_settings()
	emit_signal("closed")
	queue_free()
