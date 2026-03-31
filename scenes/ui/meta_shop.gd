extends CanvasLayer

var _gold_label: Label
var _item_widgets: Dictionary = {}  # upgrade_id -> {level_lbl, bonus_lbl, cost_lbl, btn, card_style}

const PERM_ORDER: Array = [
	"hp", "damage", "speed", "attack_speed",
	"armor", "hp_regen", "pickup_range", "gold_bonus",
]

func _ready() -> void:
	layer = 60
	_build_ui()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.size = Vector2(980, 720)
	panel.position = Vector2(960 - 490, 1080 / 2.0 - 360)
	panel.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.09)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.border_color = Color(0.7, 0.6, 0.1)
	style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title_row.add_child(title)

	_gold_label = Label.new()
	_gold_label.text = "⬡ %d" % Progression.total_gold
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", 24)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title_row.add_child(_gold_label)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.7, 0.6, 0.1, 0.5)
	sep_style.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var section_lbl := Label.new()
	section_lbl.text = "PERMANENTE UPGRADES"
	section_lbl.add_theme_font_size_override("font_size", 14)
	section_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	vbox.add_child(section_lbl)

	# 4-column card grid
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	for upgrade_id in PERM_ORDER:
		_add_upgrade_card(grid, upgrade_id)

	# Char unlocks
	var sep2 := HSeparator.new()
	var sep2_style := StyleBoxFlat.new()
	sep2_style.bg_color = Color(0.4, 0.3, 0.1, 0.5)
	sep2_style.content_margin_top = 1
	sep2.add_theme_stylebox_override("separator", sep2_style)
	vbox.add_child(sep2)

	var char_lbl := Label.new()
	char_lbl.text = "CHARAKTERE FREISCHALTEN"
	char_lbl.add_theme_font_size_override("font_size", 14)
	char_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	vbox.add_child(char_lbl)

	var char_row := HBoxContainer.new()
	char_row.add_theme_constant_override("separation", 12)
	vbox.add_child(char_row)

	for char_id in ["tank", "mage"]:
		_add_char_card(char_row, char_id)

	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(close_row)

	var close_btn := Button.new()
	close_btn.text = "SCHLIESSEN"
	close_btn.custom_minimum_size = Vector2(200, 46)
	_apply_btn_style(close_btn, Color(0.15, 0.1, 0.28), Color(0.25, 0.15, 0.45), Color(0.4, 0.2, 0.7))
	close_btn.pressed.connect(queue_free)
	close_row.add_child(close_btn)

	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.22)

func _add_upgrade_card(parent: Node, upgrade_id: String) -> void:
	var data: Dictionary = Progression.PERM_UPGRADES[upgrade_id]
	var lvl: int = Progression.perm_levels.get(upgrade_id, 0)
	var cost: int = Progression.get_perm_upgrade_cost(upgrade_id)
	var is_maxed: bool = lvl >= data["max_level"]

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 126)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.10, 0.05) if is_maxed else Color(0.09, 0.09, 0.14)
	card_style.border_width_top = 1; card_style.border_width_bottom = 1
	card_style.border_width_left = 1; card_style.border_width_right = 1
	card_style.border_color = Color(0.7, 0.6, 0.1, 0.8) if is_maxed else Color(0.3, 0.3, 0.5, 0.6)
	card_style.corner_radius_top_left = 6; card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6; card_style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	card.add_child(inner)

	var top_row := HBoxContainer.new()
	inner.add_child(top_row)

	var icon_lbl := Label.new()
	icon_lbl.text = data["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 18)
	top_row.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	top_row.add_child(name_lbl)

	var level_lbl := Label.new()
	level_lbl.text = _level_text(upgrade_id, lvl)
	level_lbl.add_theme_font_size_override("font_size", 11)
	level_lbl.add_theme_color_override("font_color",
		Color(0.6, 1.0, 0.4) if is_maxed else Color(0.6, 0.6, 0.8))
	inner.add_child(level_lbl)

	var bonus_lbl := Label.new()
	bonus_lbl.text = _bonus_text(upgrade_id, lvl)
	bonus_lbl.add_theme_font_size_override("font_size", 11)
	bonus_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
	inner.add_child(bonus_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	var btn_row := HBoxContainer.new()
	inner.add_child(btn_row)

	var cost_lbl := Label.new()
	cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_lbl.add_theme_font_size_override("font_size", 12)
	if is_maxed:
		cost_lbl.text = "MAX ✓"
		cost_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.4))
	else:
		var can_afford: bool = Progression.can_afford(cost)
		cost_lbl.text = "⬡ %d" % cost
		cost_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.2) if can_afford else Color(0.8, 0.3, 0.3))
	btn_row.add_child(cost_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 28)
	btn.add_theme_font_size_override("font_size", 12)
	if is_maxed:
		btn.text = "—"
		btn.disabled = true
		_apply_btn_style(btn, Color(0.1, 0.1, 0.1), Color(0.1, 0.1, 0.1), Color(0.3, 0.3, 0.3))
	else:
		var can_buy: bool = Progression.can_afford(cost)
		btn.text = "KAUF"
		btn.disabled = not can_buy
		_apply_btn_style(btn,
			Color(0.1, 0.25, 0.1) if can_buy else Color(0.15, 0.15, 0.15),
			Color(0.15, 0.35, 0.15),
			Color(0.3, 0.7, 0.3) if can_buy else Color(0.3, 0.3, 0.3))
		btn.pressed.connect(_on_buy_perm.bind(upgrade_id))
	btn_row.add_child(btn)

	_item_widgets[upgrade_id] = {
		"card_style": card_style, "level_lbl": level_lbl,
		"bonus_lbl": bonus_lbl, "cost_lbl": cost_lbl, "btn": btn,
	}

func _level_text(upgrade_id: String, lvl: int) -> String:
	var max_lvl: int = Progression.PERM_UPGRADES[upgrade_id]["max_level"]
	return "Lv. MAX" if lvl >= max_lvl else "Lv. %d / %d" % [lvl, max_lvl]

func _bonus_text(upgrade_id: String, lvl: int) -> String:
	if lvl == 0:
		return "Noch nicht aktiv"
	var data: Dictionary = Progression.PERM_UPGRADES[upgrade_id]
	if data.has("hp_per_level"):
		return "+%d Max HP" % (lvl * int(data["hp_per_level"]))
	elif data.has("flat_per_level"):
		return "+%d Rüstung" % int(lvl * data["flat_per_level"])
	elif data.has("regen_per_level"):
		return "+%.1f HP/s" % (lvl * data["regen_per_level"])
	else:
		return "+%d%%" % int(lvl * data["pct_per_level"])

func _add_char_card(parent: HBoxContainer, char_id: String) -> void:
	var char_data: Dictionary = Progression.CHARS[char_id]
	var is_unlocked: bool = Progression.is_char_unlocked(char_id)
	var cost: int = char_data["unlock_cost"]

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 56)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.09, 0.09, 0.14)
	card_style.border_width_top = 1; card_style.border_width_bottom = 1
	card_style.border_width_left = 1; card_style.border_width_right = 1
	card_style.border_color = Color(0.4, 0.9, 0.4, 0.8) if is_unlocked else Color(0.3, 0.3, 0.5, 0.6)
	card_style.corner_radius_top_left = 6; card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6; card_style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	card.add_child(inner)

	var name_lbl := Label.new()
	name_lbl.text = char_data["name"] + (" ✓" if is_unlocked else "")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if is_unlocked else Color(0.9, 0.9, 1.0))
	inner.add_child(name_lbl)

	if not is_unlocked:
		var cost_lbl := Label.new()
		cost_lbl.text = "⬡ %d" % cost
		cost_lbl.add_theme_font_size_override("font_size", 14)
		var can_afford: bool = Progression.can_afford(cost)
		cost_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.2) if can_afford else Color(0.8, 0.3, 0.3))
		inner.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "KAUFEN"
		btn.custom_minimum_size = Vector2(90, 32)
		_apply_btn_style(btn,
			Color(0.1, 0.25, 0.1) if can_afford else Color(0.15, 0.15, 0.15),
			Color(0.15, 0.35, 0.15),
			Color(0.3, 0.7, 0.3) if can_afford else Color(0.3, 0.3, 0.3))
		btn.disabled = not can_afford
		btn.pressed.connect(_on_buy_char.bind(char_id))
		inner.add_child(btn)

		_item_widgets[char_id] = {
			"name_lbl": name_lbl, "cost_lbl": cost_lbl,
			"btn": btn, "card_style": card_style,
		}

func _on_buy_perm(upgrade_id: String) -> void:
	if Progression.buy_perm_upgrade(upgrade_id):
		SFX.play("card_select", 0.0)
		_refresh_display()

func _on_buy_char(char_id: String) -> void:
	if Progression.buy_char_unlock(char_id):
		SFX.play("card_select", 0.0)
		_refresh_display()

func _refresh_display() -> void:
	_gold_label.text = "⬡ %d" % Progression.total_gold

	for upgrade_id in PERM_ORDER:
		if not _item_widgets.has(upgrade_id):
			continue
		var w: Dictionary = _item_widgets[upgrade_id]
		var data: Dictionary = Progression.PERM_UPGRADES[upgrade_id]
		var lvl: int = Progression.perm_levels.get(upgrade_id, 0)
		var cost: int = Progression.get_perm_upgrade_cost(upgrade_id)
		var is_maxed: bool = lvl >= data["max_level"]

		w["level_lbl"].text = _level_text(upgrade_id, lvl)
		w["bonus_lbl"].text = _bonus_text(upgrade_id, lvl)

		if is_maxed:
			w["cost_lbl"].text = "MAX ✓"
			w["cost_lbl"].add_theme_color_override("font_color", Color(0.7, 1.0, 0.4))
			w["btn"].text = "—"
			w["btn"].disabled = true
			w["card_style"].bg_color = Color(0.08, 0.10, 0.05)
			w["card_style"].border_color = Color(0.7, 0.6, 0.1, 0.8)
		else:
			var can_buy: bool = Progression.can_afford(cost)
			w["cost_lbl"].text = "⬡ %d" % cost
			w["cost_lbl"].add_theme_color_override("font_color",
				Color(1.0, 0.85, 0.2) if can_buy else Color(0.8, 0.3, 0.3))
			w["btn"].disabled = not can_buy

	for char_id in ["tank", "mage"]:
		if not _item_widgets.has(char_id):
			continue
		var is_unlocked: bool = Progression.is_char_unlocked(char_id)
		if is_unlocked:
			var w: Dictionary = _item_widgets[char_id]
			w["name_lbl"].text = Progression.CHARS[char_id]["name"] + " ✓"
			w["name_lbl"].add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			w["card_style"].border_color = Color(0.4, 0.9, 0.4, 0.8)
			if w.has("btn"):
				w["btn"].disabled = true
				w["btn"].text = "✓"

func _apply_btn_style(btn: Button, bg: Color, hover_bg: Color, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4; s.corner_radius_bottom_right = 4
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_width_left = 1; s.border_width_right = 1
	s.border_color = border
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = hover_bg
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 13)
