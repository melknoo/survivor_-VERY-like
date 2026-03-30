extends CanvasLayer

const GAME_WORLD_SCENE := "res://scenes/game_world.tscn"

var _buttons: Array = []

func _ready() -> void:
	layer = 0
	_build_ui()
	_animate_entrance()

func _build_ui() -> void:
	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.07)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Floating particle background
	_build_particles()

	# Title ribbon
	_build_title()

	# Buttons
	_build_buttons()

	# Version hint
	var version := Label.new()
	version.text = "v0.1"
	version.add_theme_color_override("font_color", Color(0.35, 0.35, 0.5))
	version.add_theme_font_size_override("font_size", 14)
	version.position = Vector2(16, 1080 - 28)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(version)

func _build_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.amount = 60
	particles.lifetime = 5.0
	particles.explosiveness = 0.0
	particles.randomness = 1.0
	particles.emitting = true
	particles.position = Vector2(960, 1080)

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(960, 10, 0)
	pmat.direction = Vector3(0, -1, 0)
	pmat.spread = 8.0
	pmat.initial_velocity_min = 30.0
	pmat.initial_velocity_max = 90.0
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 1.5
	pmat.scale_max = 3.5
	pmat.color = Color(1.0, 1.0, 1.0, 0.5)

	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(img)
	particles.process_material = pmat

	# Fade out near top via color gradient
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 0.5))
	grad.add_point(0.7, Color(1, 1, 1, 0.3))
	grad.add_point(1.0, Color(1, 1, 1, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	pmat.color_ramp = grad_tex

	add_child(particles)

func _build_title() -> void:
	# Ribbon background for title
	var ribbon := NinePatchRect.new()
	ribbon.texture = load("res://assets/UI/Ribbons/Ribbon_Yellow_3Slides.png")
	# Ribbon_Yellow_3Slides.png: 192×64, 3 horizontal slices → 64px margins
	ribbon.patch_margin_left = 64
	ribbon.patch_margin_right = 64
	ribbon.patch_margin_top = 0
	ribbon.patch_margin_bottom = 0
	ribbon.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	ribbon.size = Vector2(700, 90)
	ribbon.position = Vector2(960 - 350, 200)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ribbon)

	var title := Label.new()
	title.text = "VAMPIRE SURVIVORS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchors_preset = Control.PRESET_FULL_RECT
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "[ ENDLESS SURVIVAL ]"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(960 - 300, 300)
	subtitle.size = Vector2(600, 30)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.45, 0.7))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

func _build_buttons() -> void:
	var labels := ["SPIELEN", "EINSTELLUNGEN", "BEENDEN"]
	var start_y := 450.0

	for i in range(labels.size()):
		var btn := _make_menu_button(labels[i])
		btn.position = Vector2(960 - 160, start_y + i * 90)
		btn.modulate.a = 0.0
		add_child(btn)
		_buttons.append(btn)

func _make_menu_button(label_text: String) -> NinePatchRect:
	var container := NinePatchRect.new()
	container.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	# Button_Blue_9Slides.png: 192×192, estimated 48px margins
	container.patch_margin_left = 48
	container.patch_margin_right = 48
	container.patch_margin_top = 48
	container.patch_margin_bottom = 48
	container.size = Vector2(320, 72)
	container.mouse_filter = Control.MOUSE_FILTER_STOP

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	# Wrap in a Button for interaction (invisible on top)
	# Use an Area2D-style approach: connect input events via the NinePatchRect
	container.gui_input.connect(_on_button_gui_input.bind(container))
	container.mouse_entered.connect(_on_button_hover_enter.bind(container))
	container.mouse_exited.connect(_on_button_hover_exit.bind(container))

	return container

func _on_button_gui_input(event: InputEvent, container: NinePatchRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var idx := _buttons.find(container)
		if idx != -1:
			SFX.play("button_click", 0.0)
			match idx:
				0: _on_play()
				1: _on_settings()
				2: _on_quit()

func _on_button_hover_enter(container: NinePatchRect) -> void:
	container.texture = load("res://assets/UI/Buttons/Button_Hover_9Slides.png")
	var tw := container.create_tween()
	tw.tween_property(container, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_SINE)
	container.pivot_offset = container.size / 2.0

func _on_button_hover_exit(container: NinePatchRect) -> void:
	container.texture = load("res://assets/UI/Buttons/Button_Blue_9Slides.png")
	var tw := container.create_tween()
	tw.tween_property(container, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)

func _animate_entrance() -> void:
	# Staggered button slide-in from below
	for i in range(_buttons.size()):
		var btn: NinePatchRect = _buttons[i]
		var target_y: float = btn.position.y
		btn.position.y += 60
		var tw := btn.create_tween()
		tw.tween_interval(0.15 + i * 0.12)
		tw.tween_property(btn, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(btn, "position:y", target_y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_play() -> void:
	_fade_to_scene(GAME_WORLD_SCENE)

func _on_settings() -> void:
	var settings := CanvasLayer.new()
	settings.set_script(preload("res://scenes/ui/settings_menu.gd"))
	add_child(settings)
	settings.setup(null)

func _on_quit() -> void:
	get_tree().quit()

func _fade_to_scene(path: String) -> void:
	# Disable buttons during transition
	for btn in _buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fade := ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.z_index = 100
	add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.4)
	await tw.finished
	get_tree().change_scene_to_file(path)
