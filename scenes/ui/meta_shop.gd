extends CanvasLayer

var _gold_label: Label
var _item_labels: Dictionary = {}  # type -> {cost_lbl, btn}

func _ready() -> void:
	layer = 60
	_build_ui()

func _build_ui() -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Panel
	var panel := PanelContainer.new()
	panel.size = Vector2(800, 680)
	panel.position = Vector2(960 - 400, 1080 / 2.0 - 340)
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
	vbox.add_theme_constant_override("separation", 16)
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

	# Separator
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.7, 0.6, 0.1, 0.5)
	sep_style.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Perm upgrade rows
	var section_lbl := Label.new()
	section_lbl.text = "PERMANENTE UPGRADES"
	section_lbl.add_theme_font_size_override("font_size", 15)
	section_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	vbox.add_child(section_lbl)

	for type in ["hp", "damage", "speed"]:
		_add_perm_row(vbox, type)

	# Separator
	var sep2 := HSeparator.new()
	var sep2_style := StyleBoxFlat.new()
	sep2_style.bg_color = Color(0.4, 0.3, 0.1, 0.5)
	sep2_style.content_margin_top = 1
	sep2.add_theme_stylebox_override("separator", sep2_style)
	vbox.add_child(sep2)

	# Char unlock rows
	var char_lbl := Label.new()
	char_lbl.text = "CHARAKTERE FREISCHALTEN"
	char_lbl.add_theme_font_size_override("font_size", 15)
	char_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	vbox.add_child(char_lbl)

	for char_id in ["tank", "mage"]:
		_add_char_row(vbox, char_id)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "SCHLIESSEN"
	close_btn.custom_minimum_size = Vector2(200, 48)
	_apply_btn_style(close_btn, Color(0.15, 0.1, 0.28), Color(0.25, 0.15, 0.45), Color(0.4, 0.2, 0.7))
	close_btn.pressed.connect(queue_free)
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.add_child(close_btn)
	vbox.add_child(close_row)

	# Animate panel in
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)

func _add_perm_row(parent: VBoxContainer, type: String) -> void:
	var data: Dictionary = Progression.PERM_UPGRADES[type]
	var lvl: int = Progression.perm_levels.get(type, 0)
	var cost: int = Progression.get_perm_upgrade_cost(type)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	# Name + level
	var name_lbl := Label.new()
	var bonus_txt := ""
	if type == "hp":
		bonus_txt = "+%d HP" % (lvl * data["hp_per_level"])
	else:
		bonus_txt = "+%d%%" % int(lvl * data["pct_per_level"])
	name_lbl.text = "%s  [Lv.%d/%d]  %s" % [data["name"], lvl, data["max_level"], bonus_txt]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	row.add_child(name_lbl)

	# Cost label
	var cost_lbl := Label.new()
	cost_lbl.text = "⬡ %d" % cost if cost >= 0 else "MAX"
	cost_lbl.add_theme_font_size_override("font_size", 17)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	row.add_child(cost_lbl)

	# Buy button
	var btn := Button.new()
	btn.text = "KAUFEN"
	btn.custom_minimum_size = Vector2(110, 38)
	var can_buy: bool = cost >= 0 and Progression.can_afford(cost)
	_apply_btn_style(btn,
		Color(0.1, 0.25, 0.1) if can_buy else Color(0.15, 0.15, 0.15),
		Color(0.15, 0.35, 0.15),
		Color(0.3, 0.7, 0.3) if can_buy else Color(0.3, 0.3, 0.3))
	btn.disabled = not can_buy
	btn.pressed.connect(_on_buy_perm.bind(type))
	row.add_child(btn)

	_item_labels[type] = {"name_lbl": name_lbl, "cost_lbl": cost_lbl, "btn": btn}

func _add_char_row(parent: VBoxContainer, char_id: String) -> void:
	var char_data: Dictionary = Progression.CHARS[char_id]
	var is_unlocked: bool = Progression.is_char_unlocked(char_id)
	var cost: int = char_data["unlock_cost"]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = char_data["name"] + ("  [FREIGESCHALTET]" if is_unlocked else "")
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if is_unlocked else Color(0.9, 0.9, 1.0))
	row.add_child(name_lbl)

	if not is_unlocked:
		var cost_lbl := Label.new()
		cost_lbl.text = "⬡ %d" % cost
		cost_lbl.add_theme_font_size_override("font_size", 17)
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		row.add_child(cost_lbl)

		var btn := Button.new()
		btn.text = "KAUFEN"
		btn.custom_minimum_size = Vector2(110, 38)
		var can_buy: bool = Progression.can_afford(cost)
		_apply_btn_style(btn,
			Color(0.1, 0.25, 0.1) if can_buy else Color(0.15, 0.15, 0.15),
			Color(0.15, 0.35, 0.15),
			Color(0.3, 0.7, 0.3) if can_buy else Color(0.3, 0.3, 0.3))
		btn.disabled = not can_buy
		btn.pressed.connect(_on_buy_char.bind(char_id))
		row.add_child(btn)

		_item_labels[char_id] = {"name_lbl": name_lbl, "cost_lbl": cost_lbl, "btn": btn}

func _on_buy_perm(type: String) -> void:
	if Progression.buy_perm_upgrade(type):
		SFX.play("card_select", 0.0)
		_refresh_display()

func _on_buy_char(char_id: String) -> void:
	if Progression.buy_char_unlock(char_id):
		SFX.play("card_select", 0.0)
		_refresh_display()

func _refresh_display() -> void:
	_gold_label.text = "⬡ %d" % Progression.total_gold

	for type in ["hp", "damage", "speed"]:
		if not _item_labels.has(type):
			continue
		var data: Dictionary = Progression.PERM_UPGRADES[type]
		var lvl: int = Progression.perm_levels.get(type, 0)
		var cost: int = Progression.get_perm_upgrade_cost(type)
		var labels = _item_labels[type]
		var bonus_txt := ""
		if type == "hp":
			bonus_txt = "+%d HP" % (lvl * data["hp_per_level"])
		else:
			bonus_txt = "+%d%%" % int(lvl * data["pct_per_level"])
		labels["name_lbl"].text = "%s  [Lv.%d/%d]  %s" % [data["name"], lvl, data["max_level"], bonus_txt]
		labels["cost_lbl"].text = "⬡ %d" % cost if cost >= 0 else "MAX"
		var can_buy: bool = cost >= 0 and Progression.can_afford(cost)
		labels["btn"].disabled = not can_buy

	for char_id in ["tank", "mage"]:
		if not _item_labels.has(char_id):
			continue
		var is_unlocked: bool = Progression.is_char_unlocked(char_id)
		var labels = _item_labels[char_id]
		if is_unlocked:
			labels["name_lbl"].text = Progression.CHARS[char_id]["name"] + "  [FREIGESCHALTET]"
			labels["name_lbl"].add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			if labels.has("btn"):
				labels["btn"].disabled = true
				labels["btn"].text = "✓"

func _apply_btn_style(btn: Button, bg: Color, hover_bg: Color, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 5; s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5; s.corner_radius_bottom_right = 5
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_width_left = 1; s.border_width_right = 1
	s.border_color = border
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = hover_bg
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
	btn.add_theme_font_size_override("font_size", 15)
