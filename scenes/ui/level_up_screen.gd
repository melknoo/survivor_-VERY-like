extends CanvasLayer

signal upgrade_chosen(upgrade_id: String)

const CARD_W := 210
const CARD_H := 310
const CARD_GAP := 32

const TEX_CARD   := "res://assets/UI/Banners/Carved_9Slides.png"
const TEX_RIBBON := "res://assets/UI/Ribbons/Ribbon_Yellow_3Slides.png"
const TEX_ITEMS  := "res://assets/items/items.png"

var _choices: Array = []
var _upgrade_manager: Node
var _cards: Array = []
var _card_orig_y: Array = []
var _overlay: ColorRect
var _title_ribbon: NinePatchRect
var _title: Label
var _chosen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30

func setup(choices: Array, mgr: Node) -> void:
	_choices = choices
	_upgrade_manager = mgr
	_build_ui()
	_animate_in()

func _build_ui() -> void:
	# Fullscreen dark overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Title ribbon background
	_title_ribbon = NinePatchRect.new()
	_title_ribbon.texture = load(TEX_RIBBON)
	_title_ribbon.patch_margin_left = 48
	_title_ribbon.patch_margin_right = 48
	_title_ribbon.patch_margin_top = 10
	_title_ribbon.patch_margin_bottom = 10
	_title_ribbon.size = Vector2(560.0, 76.0)
	_title_ribbon.position = Vector2(680.0, 196.0)
	_title_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_ribbon.modulate.a = 0.0
	add_child(_title_ribbon)

	# "LEVEL UP!" label on top of ribbon
	_title = Label.new()
	_title.text = "LEVEL UP!"
	_title.size = Vector2(560.0, 76.0)
	_title.position = Vector2(680.0, 196.0)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color(0.18, 0.08, 0.01))
	_title.add_theme_color_override("font_shadow_color", Color(1.0, 0.9, 0.3, 0.6))
	_title.add_theme_constant_override("shadow_offset_x", 1)
	_title.add_theme_constant_override("shadow_offset_y", 2)
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	# Cards centered on screen
	var n := _choices.size()
	var total_w := n * CARD_W + (n - 1) * CARD_GAP
	var start_x := 960.0 - total_w * 0.5
	var card_y := 320.0

	for i in range(n):
		var card := _make_card(_choices[i], start_x + i * (CARD_W + CARD_GAP), card_y, i)
		_card_orig_y.append(card_y)
		card.modulate.a = 0.0
		card.position.y = 920.0
		_cards.append(card)
		add_child(card)

func _make_card(upg: Dictionary, x: float, y: float, idx: int) -> Control:
	# Root control (handles input + scale pivot)
	var card := Control.new()
	card.size = Vector2(CARD_W, CARD_H)
	card.position = Vector2(x, y)
	card.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Parchment / stone NinePatchRect background
	var bg := NinePatchRect.new()
	bg.texture = load(TEX_CARD)
	bg.patch_margin_left = 40
	bg.patch_margin_right = 40
	bg.patch_margin_top = 40
	bg.patch_margin_bottom = 40
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg)

	# Rarity color strip at bottom (absolute – stays outside container)
	var rc := _rarity_color(upg["rarity"])
	var strip := ColorRect.new()
	strip.color = rc
	strip.size = Vector2(CARD_W - 24.0, 5.0)
	strip.position = Vector2(12.0, CARD_H - 18.0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(strip)

	# MarginContainer fills the card and gives children their width
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Icon
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = load(TEX_ITEMS)
	atlas_tex.region = upg["icon_region"]
	var icon := TextureRect.new()
	icon.texture = atlas_tex
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(64.0, 64.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	# Upgrade name
	var nl := Label.new()
	nl.text = upg["name"]
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.add_theme_font_size_override("font_size", 15)
	nl.add_theme_color_override("font_color", Color(0.15, 0.06, 0.01))
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(nl)

	# Rarity text
	var rl := Label.new()
	rl.text = _rarity_text(upg["rarity"])
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.add_theme_font_size_override("font_size", 10)
	rl.add_theme_color_override("font_color", rc.darkened(0.15))
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rl)

	# Divider line
	var div := ColorRect.new()
	div.color = Color(0.35, 0.22, 0.1, 0.5)
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(div)

	# Description
	var cur_lvl: int = _upgrade_manager.get_upgrade_level(upg["id"])
	var dl := Label.new()
	var desc: String = upg["description"]
	if "%s" in desc:
		var val: float = float(upg["values"][cur_lvl])
		var val_str: String = "%.1f" % val if val != float(int(val)) else str(int(val))
		dl.text = desc % val_str
	else:
		dl.text = desc
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dl.add_theme_font_size_override("font_size", 13)
	dl.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(dl)

	# Spacer pushes level label to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# Level indicator
	var ll := Label.new()
	ll.text = "✦ NEU ✦" if cur_lvl == 0 else "Lv. %d  →  %d" % [cur_lvl, cur_lvl + 1]
	ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ll.add_theme_font_size_override("font_size", 13)
	ll.add_theme_color_override("font_color", Color(0.1, 0.4, 0.1))
	ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ll)

	# Hover and click
	card.mouse_entered.connect(_on_hover_enter.bind(card))
	card.mouse_exited.connect(_on_hover_exit.bind(card))
	card.gui_input.connect(_on_card_input.bind(upg["id"], idx))

	return card

# --- Hover ---

func _on_hover_enter(card: Control) -> void:
	if _chosen:
		return
	var tw := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "scale", Vector2(1.06, 1.06), 0.12)
	tw.parallel().tween_property(card, "modulate", Color(1.15, 1.1, 0.9), 0.12)

func _on_hover_exit(card: Control) -> void:
	if _chosen:
		return
	var tw := card.create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.1)
	tw.parallel().tween_property(card, "modulate", Color.WHITE, 0.1)

# --- Click ---

func _on_card_input(event: InputEvent, upgrade_id: String, card_idx: int) -> void:
	if _chosen:
		return
	if not (event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed):
		return
	_chosen = true

	var chosen_card: Control = _cards[card_idx]
	var ct := chosen_card.create_tween().set_ease(Tween.EASE_IN_OUT)
	ct.tween_property(chosen_card, "scale", Vector2(1.2, 1.2), 0.1)
	ct.tween_property(chosen_card, "scale", Vector2.ZERO, 0.15)

	for i in range(_cards.size()):
		if i == card_idx:
			continue
		var other: Control = _cards[i]
		var ot: Tween = other.create_tween()
		ot.tween_property(other, "modulate:a", 0.0, 0.15)

	await get_tree().create_timer(0.3).timeout
	_close(upgrade_id)

# --- Animations ---

func _animate_in() -> void:
	var ot := create_tween()
	ot.tween_property(_overlay, "color:a", 0.72, 0.3)

	# Title + ribbon drop from above
	_title_ribbon.position.y = 110.0
	_title.position.y = 110.0
	var tt := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tt.tween_interval(0.06)
	tt.tween_property(_title_ribbon, "position:y", 196.0, 0.38)
	tt.parallel().tween_property(_title_ribbon, "modulate:a", 1.0, 0.22)
	tt.parallel().tween_property(_title, "position:y", 196.0, 0.38)
	tt.parallel().tween_property(_title, "modulate:a", 1.0, 0.22)

	# Cards fly up from below staggered
	for i in range(_cards.size()):
		var card: Control = _cards[i]
		var orig_y: float = _card_orig_y[i]
		var ct := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		ct.tween_interval(0.15 + i * 0.08)
		ct.tween_property(card, "position:y", orig_y, 0.32)
		ct.parallel().tween_property(card, "modulate:a", 1.0, 0.15)

func _close(upgrade_id: String) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_overlay, "color:a", 0.0, 0.2)
	tw.tween_property(_title_ribbon, "modulate:a", 0.0, 0.15)
	tw.tween_property(_title, "modulate:a", 0.0, 0.15)
	for card: Control in _cards:
		tw.tween_property(card, "modulate:a", 0.0, 0.15)
	await tw.finished
	emit_signal("upgrade_chosen", upgrade_id)
	queue_free()

# --- Helpers ---

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"uncommon": return Color(0.15, 0.65, 0.25)
		"rare":     return Color(0.85, 0.55, 0.05)
		_:          return Color(0.45, 0.42, 0.38)

func _rarity_text(rarity: String) -> String:
	match rarity:
		"uncommon": return "◆ UNGEWÖHNLICH"
		"rare":     return "◆ SELTEN"
		_:          return "◆ GEWÖHNLICH"
