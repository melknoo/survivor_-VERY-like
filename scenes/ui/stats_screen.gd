extends CanvasLayer

signal closed

const TEX_CARD   := "res://assets/UI/Banners/Carved_9Slides.png"
const TEX_RIBBON := "res://assets/UI/Ribbons/Ribbon_Yellow_3Slides.png"

var _player: Node
var _upgrade_manager: Node
var _overlay: ColorRect
var _container: Control  # wraps all UI except overlay for unified fade/scale

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 35

func setup(player: Node, upgrade_manager: Node) -> void:
	_player = player
	_upgrade_manager = upgrade_manager
	_build_ui()
	_animate_in()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_stats") or \
			(event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE and event.pressed):
		get_viewport().set_input_as_handled()
		_close()

func _build_ui() -> void:
	# Dark overlay (separate so it doesn't scale with content)
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Container for everything else — scale-pivot at screen center
	_container = Control.new()
	_container.anchors_preset = Control.PRESET_FULL_RECT
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.pivot_offset = Vector2(960.0, 540.0)
	add_child(_container)

	# Title ribbon
	var ribbon := NinePatchRect.new()
	ribbon.texture = load(TEX_RIBBON)
	ribbon.patch_margin_left = 48
	ribbon.patch_margin_right = 48
	ribbon.patch_margin_top = 10
	ribbon.patch_margin_bottom = 10
	ribbon.size = Vector2(480.0, 76.0)
	ribbon.position = Vector2(720.0, 110.0)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(ribbon)

	var title := Label.new()
	title.text = "CHARAKTER"
	title.size = Vector2(480.0, 76.0)
	title.position = Vector2(720.0, 110.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.18, 0.08, 0.01))
	title.add_theme_color_override("font_shadow_color", Color(1.0, 0.9, 0.3, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(title)

	# Main parchment panel
	var panel := NinePatchRect.new()
	panel.texture = load(TEX_CARD)
	panel.patch_margin_left = 40
	panel.patch_margin_right = 40
	panel.patch_margin_top = 40
	panel.patch_margin_bottom = 40
	panel.size = Vector2(880.0, 580.0)
	panel.position = Vector2(520.0, 200.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.add_child(panel)

	_populate_stats(panel.position)

	# Close hint
	var hint := Label.new()
	hint.text = "[C] oder [ESC] schließen"
	hint.size = Vector2(880.0, 28.0)
	hint.position = Vector2(520.0, 796.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5, 0.8))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(hint)

func _populate_stats(panel_pos: Vector2) -> void:
	var px := panel_pos.x
	var py := panel_pos.y
	var col_left  := px + 52.0
	var col_right := px + 476.0
	var row_start := py + 56.0
	var row_h     := 56.0

	# Section headers
	_add_header("ATTRIBUTE", col_left, py + 24.0)
	_add_header("UPGRADES",  col_right, py + 24.0)

	# Vertical divider
	var vdiv := ColorRect.new()
	vdiv.color = Color(0.35, 0.22, 0.1, 0.4)
	vdiv.size = Vector2(2.0, 510.0)
	vdiv.position = Vector2(px + 448.0, py + 20.0)
	vdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(vdiv)

	# Stats rows
	var stats_data: Array = [
		["❤  Leben",           "%d / %d" % [_player.current_hp, _player.max_hp]],
		["⚔  Schaden",         "%.1f" % _player.attack_damage],
		["⚡  Geschwindigkeit", "%.0f" % _player.move_speed],
		["🗡  Angriffstempo",   "%.2fx" % _player.attack_speed],
		["🧲  Aufnahmeradius",  "%.0f" % _player.pickup_range],
		["🛡  Rüstung",         "%.0f" % _player.armor],
		["💚  Regeneration",    "%.1f HP/s" % _player.hp_regen],
	]

	for i in range(stats_data.size()):
		_add_stat_row(stats_data[i][0], stats_data[i][1], col_left, row_start + i * row_h)

	# Upgrades column
	var upgrades: Array = _upgrade_manager.get_all_upgrades()
	var shown := 0
	for upg in upgrades:
		var lvl: int = _upgrade_manager.get_upgrade_level(upg["id"])
		if lvl == 0:
			continue
		_add_upgrade_row(upg["name"], lvl, upg["max_level"], col_right, row_start + shown * row_h)
		shown += 1

	if shown == 0:
		var none := Label.new()
		none.text = "–– keine ––"
		none.position = Vector2(col_right, row_start)
		none.add_theme_font_size_override("font_size", 15)
		none.add_theme_color_override("font_color", Color(0.5, 0.45, 0.38))
		none.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(none)

func _add_header(text: String, x: float, y: float) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(380.0, 26.0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.32, 0.08))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(lbl)

func _add_stat_row(label_text: String, value_text: String, x: float, y: float) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(260.0, 30.0)
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.1, 0.03))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.position = Vector2(x + 260.0, y)
	val.size = Vector2(124.0, 30.0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 17)
	val.add_theme_color_override("font_color", Color(0.08, 0.42, 0.14))
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(val)

	var div := ColorRect.new()
	div.color = Color(0.35, 0.22, 0.1, 0.22)
	div.size = Vector2(380.0, 1.0)
	div.position = Vector2(x, y + 34.0)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(div)

func _add_upgrade_row(upg_name: String, level: int, max_lvl: int, x: float, y: float) -> void:
	var lbl := Label.new()
	lbl.text = upg_name
	lbl.position = Vector2(x, y)
	lbl.size = Vector2(200.0, 30.0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.1, 0.03))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(lbl)

	# Filled pips = levels taken, dark pips = remaining
	for j in range(max_lvl):
		var pip := ColorRect.new()
		pip.size = Vector2(14.0, 14.0)
		pip.position = Vector2(x + 205.0 + j * 17.0, y + 8.0)
		pip.color = Color(0.1, 0.55, 0.2) if j < level else Color(0.28, 0.23, 0.16)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(pip)

	var div := ColorRect.new()
	div.color = Color(0.35, 0.22, 0.1, 0.22)
	div.size = Vector2(380.0, 1.0)
	div.position = Vector2(x, y + 34.0)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(div)

func _animate_in() -> void:
	_container.scale = Vector2(0.93, 0.93)
	_container.modulate.a = 0.0
	var ot := create_tween()
	ot.tween_property(_overlay, "color:a", 0.65, 0.22)
	var ct := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ct.tween_property(_container, "scale", Vector2.ONE, 0.28)
	ct.parallel().tween_property(_container, "modulate:a", 1.0, 0.18)

func _close() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "color:a", 0.0, 0.18)
	tw.tween_property(_container, "scale", Vector2(0.93, 0.93), 0.18)
	tw.tween_property(_container, "modulate:a", 0.0, 0.15)
	await tw.finished
	emit_signal("closed")
	queue_free()
