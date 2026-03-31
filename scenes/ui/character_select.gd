extends CanvasLayer

const GAME_WORLD_SCENE := "res://scenes/game_world.tscn"
const ROGUES_TEX := preload("res://assets/Characters/rogues.png")

const CHAR_ORDER := ["rogue", "bowman", "tank", "mage"]

var _cards: Array = []

func _ready() -> void:
	layer = 0
	_build_ui()
	_animate_entrance()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.07)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Title
	var title_ribbon := NinePatchRect.new()
	title_ribbon.texture = load("res://assets/UI/Ribbons/Ribbon_Yellow_3Slides.png")
	title_ribbon.patch_margin_left = 64
	title_ribbon.patch_margin_right = 64
	title_ribbon.patch_margin_top = 0
	title_ribbon.patch_margin_bottom = 0
	title_ribbon.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	title_ribbon.size = Vector2(600, 80)
	title_ribbon.position = Vector2(960 - 300, 80)
	title_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_ribbon)

	var title := Label.new()
	title.text = "CHARAKTER WÄHLEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchors_preset = Control.PRESET_FULL_RECT
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_ribbon.add_child(title)

	# Gold display (top right)
	var gold_lbl := Label.new()
	gold_lbl.text = "⬡ %d" % Progression.total_gold
	gold_lbl.position = Vector2(1700, 30)
	gold_lbl.size = Vector2(180, 40)
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_lbl.add_theme_font_size_override("font_size", 22)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	gold_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gold_lbl)

	# Character cards
	var card_count := CHAR_ORDER.size()
	var card_w := 280.0
	var card_h := 420.0
	var spacing := 40.0
	var total_w := card_count * card_w + (card_count - 1) * spacing
	var start_x := 960.0 - total_w / 2.0

	for i in range(card_count):
		var char_id: String = CHAR_ORDER[i]
		var card := _build_card(char_id, card_w, card_h)
		card.position = Vector2(start_x + i * (card_w + spacing), 300)
		card.modulate.a = 0.0
		add_child(card)
		_cards.append(card)

	# Back button
	var back_btn := _make_small_button("← ZURÜCK")
	back_btn.position = Vector2(960.0 - back_btn.size.x / 2.0, 980.0)
	back_btn.gui_input.connect(_on_back_input.bind(back_btn))
	back_btn.mouse_entered.connect(_on_btn_hover_enter.bind(back_btn))
	back_btn.mouse_exited.connect(_on_btn_hover_exit.bind(back_btn))
	add_child(back_btn)

func _build_card(char_id: String, w: float, h: float) -> Control:
	var data: Dictionary = Progression.CHARS[char_id]
	var is_unlocked: bool = Progression.is_char_unlocked(char_id)

	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)
	container.size = Vector2(w, h)
	container.set_meta("char_id", char_id)

	# Card background
	var bg := NinePatchRect.new()
	bg.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	bg.patch_margin_left = 48
	bg.patch_margin_right = 48
	bg.patch_margin_top = 48
	bg.patch_margin_bottom = 48
	bg.size = Vector2(w, h)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.set_meta("char_id", char_id)
	bg.set_meta("is_unlocked", is_unlocked)
	container.add_child(bg)

	# Character sprite (4x scale = 128x128)
	var sprite := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = ROGUES_TEX
	atlas.region = Rect2(data["sprite_col"] * 32, data["sprite_row"] * 32, 32, 32)
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.size = Vector2(128, 128)
	sprite.position = Vector2(w / 2.0 - 64, 30)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(sprite)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data["name"].to_upper()
	name_lbl.size = Vector2(w, 32)
	name_lbl.position = Vector2(0, 170)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(name_lbl)

	# Stats
	var stats_text := "❤ %d  |  ⚡ %d  |  ⚔ %d" % [data["hp"], int(data["speed"]), int(data["damage"])]
	var stats_lbl := Label.new()
	stats_lbl.text = stats_text
	stats_lbl.size = Vector2(w - 20, 60)
	stats_lbl.position = Vector2(10, 210)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(stats_lbl)

	# Weapon label
	var weapon_names := {
		"weapon_knives": "Klingen",
		"weapon_orbiter": "Orbiter",
		"weapon_garlic": "Knoblauch-Aura",
		"weapon_lightning": "Kettenblitz",
	}
	var wpn_lbl := Label.new()
	wpn_lbl.text = "Waffe: " + weapon_names.get(data["weapon"], data["weapon"])
	wpn_lbl.size = Vector2(w - 20, 30)
	wpn_lbl.position = Vector2(10, 270)
	wpn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wpn_lbl.add_theme_font_size_override("font_size", 13)
	wpn_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
	wpn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(wpn_lbl)

	if is_unlocked:
		# Separator
		var sep := HSeparator.new()
		var sep_style := StyleBoxFlat.new()
		sep_style.bg_color = Color(0.3, 0.3, 0.5, 0.5)
		sep_style.content_margin_top = 1
		sep.add_theme_stylebox_override("separator", sep_style)
		sep.size = Vector2(w - 40, 4)
		sep.position = Vector2(20, 315)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(sep)

		var select_lbl := Label.new()
		select_lbl.text = "[ AUSWÄHLEN ]"
		select_lbl.size = Vector2(w, 30)
		select_lbl.position = Vector2(0, h - 50)
		select_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		select_lbl.add_theme_font_size_override("font_size", 16)
		select_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		select_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(select_lbl)

		bg.gui_input.connect(_on_card_input.bind(bg))
		bg.mouse_entered.connect(_on_card_hover_enter.bind(bg))
		bg.mouse_exited.connect(_on_card_hover_exit.bind(bg))
	else:
		# Locked overlay
		var lock_overlay := ColorRect.new()
		lock_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
		lock_overlay.size = Vector2(w, h)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(lock_overlay)

		var cost: int = Progression.get_char_unlock_cost(char_id)
		var lock_lbl := Label.new()
		lock_lbl.text = "⬡ %d" % cost
		lock_lbl.size = Vector2(w, 40)
		lock_lbl.position = Vector2(0, h / 2.0 - 20)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 26)
		lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(lock_lbl)

		var lock_sub := Label.new()
		lock_sub.text = "GESPERRT"
		lock_sub.size = Vector2(w, 28)
		lock_sub.position = Vector2(0, h / 2.0 + 24)
		lock_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_sub.add_theme_font_size_override("font_size", 15)
		lock_sub.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
		lock_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(lock_sub)

	return container

func _make_small_button(txt: String) -> NinePatchRect:
	var btn := NinePatchRect.new()
	btn.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	btn.patch_margin_left = 48
	btn.patch_margin_right = 48
	btn.patch_margin_top = 48
	btn.patch_margin_bottom = 48
	btn.size = Vector2(200, 56)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var lbl := Label.new()
	lbl.text = txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	return btn

func _animate_entrance() -> void:
	for i in range(_cards.size()):
		var card: Control = _cards[i]
		var target_y: float = card.position.y
		card.position.y += 50
		var tw := card.create_tween()
		tw.tween_interval(0.1 + i * 0.1)
		tw.tween_property(card, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(card, "position:y", target_y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_card_input(event: InputEvent, bg: NinePatchRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var char_id: String = bg.get_meta("char_id")
		SFX.play("card_select", 0.0)
		Progression.selected_char = char_id
		Progression.save()
		_fade_to_game()

func _on_card_hover_enter(bg: NinePatchRect) -> void:
	bg.texture = load("res://assets/UI/Buttons/Button_Hover_9Slides.png")
	SFX.play("card_hover", 0.0)
	var tw := bg.create_tween()
	tw.tween_property(bg, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_SINE)
	bg.pivot_offset = bg.size / 2.0

func _on_card_hover_exit(bg: NinePatchRect) -> void:
	bg.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	var tw := bg.create_tween()
	tw.tween_property(bg, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _on_back_input(event: InputEvent, btn: NinePatchRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SFX.play("button_click", 0.0)
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_btn_hover_enter(btn: NinePatchRect) -> void:
	btn.texture = load("res://assets/UI/Buttons/Button_Hover_9Slides.png")
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_SINE)
	btn.pivot_offset = btn.size / 2.0

func _on_btn_hover_exit(btn: NinePatchRect) -> void:
	btn.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _fade_to_game() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.z_index = 100
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file(GAME_WORLD_SCENE)
