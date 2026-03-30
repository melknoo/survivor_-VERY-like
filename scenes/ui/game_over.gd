extends CanvasLayer

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(survival_time: float, kills: int, level: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Fade in background
	var fade := create_tween()
	fade.tween_property(overlay, "color:a", 0.82, 0.6)

	# Panel
	var panel := PanelContainer.new()
	panel.size = Vector2(480, 360)
	panel.position = Vector2(1920 / 2.0 - 240, 1080 / 2.0 - 180)
	panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.10)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.2, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Panel contents
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# Separator
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.4, 0.2, 0.7, 0.6)
	sep_style.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Stats
	var minutes := int(survival_time) / 60
	var seconds := int(survival_time) % 60

	for stat in [
		["Survived", "%d:%02d" % [minutes, seconds]],
		["Kills", str(kills)],
		["Level", str(level)],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		vbox.add_child(row)

		var key_label := Label.new()
		key_label.text = stat[0]
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		key_label.add_theme_font_size_override("font_size", 18)
		row.add_child(key_label)

		var val_label := Label.new()
		val_label.text = stat[1]
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
		val_label.add_theme_font_size_override("font_size", 18)
		row.add_child(val_label)

	vbox.add_child(Control.new())  # Spacer

	# Button row
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	# Restart button
	var btn := Button.new()
	btn.text = "Nochmal"
	btn.custom_minimum_size = Vector2(180, 48)
	_apply_btn_style(btn, Color(0.25, 0.1, 0.45), Color(0.35, 0.15, 0.6), Color(0.6, 0.3, 0.9))
	btn.pressed.connect(_on_restart)
	hbox.add_child(btn)

	# Main menu button
	var menu_btn := Button.new()
	menu_btn.text = "Hauptmenü"
	menu_btn.custom_minimum_size = Vector2(180, 48)
	_apply_btn_style(menu_btn, Color(0.1, 0.12, 0.28), Color(0.18, 0.2, 0.40), Color(0.3, 0.4, 0.75))
	menu_btn.pressed.connect(_on_main_menu)
	hbox.add_child(menu_btn)

	# Fade in panel
	await get_tree().create_timer(0.4).timeout
	var panel_tween := create_tween()
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	panel_tween.tween_property(panel, "position:y", panel.position.y - 10, 0.4).from(panel.position.y + 20)

func _apply_btn_style(btn: Button, bg: Color, hover_bg: Color, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_width_left = 1; s.border_width_right = 1
	s.border_color = border
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = hover_bg
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 18)

func _on_restart() -> void:
	SFX.play("button_click", 0.0)
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	SFX.play("button_click", 0.0)
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
