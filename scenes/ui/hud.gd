extends CanvasLayer

var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _level_label: Label
var _timer_label: Label
var _kill_label: Label
var _gold_label: Label

func _ready() -> void:
	add_to_group("hud")
	layer = 5
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.anchors_preset = Control.PRESET_FULL_RECT
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# === XP Bar (full width, top) ===
	_xp_bar = ProgressBar.new()
	_xp_bar.min_value = 0.0
	_xp_bar.max_value = 10.0
	_xp_bar.value = 0.0
	_xp_bar.show_percentage = false
	_xp_bar.size = Vector2(1920, 12)
	_xp_bar.position = Vector2(0, 0)

	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.08, 0.08, 0.14)
	_xp_bar.add_theme_stylebox_override("background", xp_bg)

	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.2, 0.6, 1.0)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	root.add_child(_xp_bar)

	# === HP Bar (top left) ===
	var hp_container := VBoxContainer.new()
	hp_container.position = Vector2(20, 22)
	hp_container.size = Vector2(200, 40)
	root.add_child(hp_container)

	var hp_label := Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_container.add_child(hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(200, 16)

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.18, 0.06, 0.06)
	hp_bg.corner_radius_top_left = 4
	hp_bg.corner_radius_top_right = 4
	hp_bg.corner_radius_bottom_left = 4
	hp_bg.corner_radius_bottom_right = 4
	_hp_bar.add_theme_stylebox_override("background", hp_bg)

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.85, 0.15, 0.1)
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_container.add_child(_hp_bar)

	# === Level label (next to XP bar) ===
	_level_label = Label.new()
	_level_label.text = "Lv.1"
	_level_label.position = Vector2(20, 70)
	_level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_level_label.add_theme_font_size_override("font_size", 18)
	root.add_child(_level_label)

	# === Timer (top right) ===
	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.size = Vector2(120, 30)
	_timer_label.position = Vector2(1780, 22)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_timer_label.add_theme_font_size_override("font_size", 20)
	root.add_child(_timer_label)

	# === Kill counter (below timer) ===
	_kill_label = Label.new()
	_kill_label.text = "☠ 0"
	_kill_label.size = Vector2(120, 30)
	_kill_label.position = Vector2(1780, 52)
	_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kill_label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.9))
	_kill_label.add_theme_font_size_override("font_size", 16)
	root.add_child(_kill_label)

	# === Gold counter (below kills) ===
	_gold_label = Label.new()
	_gold_label.text = "⬡ 0"
	_gold_label.size = Vector2(120, 30)
	_gold_label.position = Vector2(1780, 78)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_gold_label.add_theme_font_size_override("font_size", 16)
	root.add_child(_gold_label)

func update_hp(current: int, maximum: int) -> void:
	if not _hp_bar:
		return
	_hp_bar.max_value = maximum
	var tween := create_tween()
	tween.tween_property(_hp_bar, "value", float(current), 0.15)

func update_xp(current: int, required: int) -> void:
	if not _xp_bar:
		return
	_xp_bar.max_value = float(required)
	var tween := create_tween()
	tween.tween_property(_xp_bar, "value", float(current), 0.2)

func update_level(new_level: int) -> void:
	if not _level_label:
		return
	_level_label.text = "Lv.%d" % new_level

	# Bounce animation
	_level_label.pivot_offset = _level_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(_level_label, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(_level_label, "scale", Vector2(1.0, 1.0), 0.15)

func update_time(time: float) -> void:
	if not _timer_label:
		return
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	_timer_label.text = "%d:%02d" % [minutes, seconds]

func update_kills(count: int) -> void:
	if not _kill_label:
		return
	_kill_label.text = "☠ %d" % count

	# Scale bounce
	_kill_label.pivot_offset = _kill_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(_kill_label, "scale", Vector2(1.3, 1.3), 0.06)
	tween.tween_property(_kill_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_gold(amount: int) -> void:
	if not _gold_label:
		return
	_gold_label.text = "⬡ %d" % amount
	_gold_label.pivot_offset = _gold_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(_gold_label, "scale", Vector2(1.3, 1.3), 0.06)
	tween.tween_property(_gold_label, "scale", Vector2(1.0, 1.0), 0.1)
