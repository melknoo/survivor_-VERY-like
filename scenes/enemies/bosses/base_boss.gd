extends "res://scenes/enemies/base_enemy.gd"

signal boss_died
signal boss_hp_changed(current: float, maximum: float)

@export var boss_name: String = "Boss"

var _is_boss: bool = true
var _current_phase: int = 1
var _boss_bar_layer: CanvasLayer
var _boss_bar_fill: ColorRect
var _boss_bar_label: Label

func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	_health_bar_container.visible = false  # Use the big bar instead

func _setup_boss_bar() -> void:
	_boss_bar_layer = CanvasLayer.new()
	_boss_bar_layer.layer = 6
	_boss_bar_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var bar_w := 1600.0
	var bar_h := 20.0
	var bar_x := (1920.0 - bar_w) * 0.5
	var bar_y := 28.0

	# Slide in from above
	_boss_bar_layer.offset = Vector2(0.0, -(bar_y + bar_h + 20.0))

	# Container
	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_layer.add_child(container)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.02, 0.02)
	bg.size = Vector2(bar_w + 4.0, bar_h + 4.0)
	bg.position = Vector2(bar_x - 2.0, bar_y - 2.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Gold border
	for border_data in [
		[Vector2(bar_x - 2.0, bar_y - 2.0), Vector2(bar_w + 4.0, 2.0)],
		[Vector2(bar_x - 2.0, bar_y + bar_h), Vector2(bar_w + 4.0, 2.0)],
		[Vector2(bar_x - 2.0, bar_y - 2.0), Vector2(2.0, bar_h + 4.0)],
		[Vector2(bar_x + bar_w, bar_y - 2.0), Vector2(2.0, bar_h + 4.0)],
	]:
		var b := ColorRect.new()
		b.color = Color(0.85, 0.68, 0.1)
		b.position = border_data[0]
		b.size = border_data[1]
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(b)

	# Fill (full width = full HP)
	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.color = Color(0.75, 0.05, 0.05)
	_boss_bar_fill.size = Vector2(bar_w, bar_h)
	_boss_bar_fill.position = Vector2(bar_x, bar_y)
	_boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(_boss_bar_fill)

	# Boss name label
	_boss_bar_label = Label.new()
	_boss_bar_label.text = boss_name.to_upper()
	_boss_bar_label.position = Vector2(bar_x, bar_y - 24.0)
	_boss_bar_label.add_theme_font_size_override("font_size", 16)
	_boss_bar_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.15))
	_boss_bar_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_boss_bar_label.add_theme_constant_override("shadow_offset_x", 1)
	_boss_bar_label.add_theme_constant_override("shadow_offset_y", 1)
	_boss_bar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(_boss_bar_label)

	get_tree().root.add_child(_boss_bar_layer)

	# Slide in animation
	var tw := _boss_bar_layer.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_boss_bar_layer, "offset", Vector2.ZERO, 0.5)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	emit_signal("boss_hp_changed", current_hp, max_hp)
	_update_boss_bar()

func _update_boss_bar() -> void:
	if not is_instance_valid(_boss_bar_fill):
		return
	var pct := current_hp / max_hp
	var tw := create_tween()
	tw.tween_property(_boss_bar_fill, "size:x", 1600.0 * pct, 0.15)

func _die() -> void:
	emit_signal("boss_died")
	_boss_death_sequence()

func _boss_death_sequence() -> void:
	set_physics_process(false)
	collision_layer = 0
	if is_instance_valid(_contact_area):
		_contact_area.monitoring = false

	SFX.play("enemy_die", 0.0, 4.0)

	var cam := get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(12.0, 0.8)

	Engine.time_scale = 0.2

	# Notify kill counter
	var gw := get_tree().get_first_node_in_group("game_world")
	if gw:
		gw.increment_kill_count()

	# Series of mini-explosions in real time
	for i in range(7):
		var timer := get_tree().create_timer(float(i) * 0.08, true, false, true)
		timer.timeout.connect(_spawn_boss_explosion.bind(
			global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		))

	# Final sequence after 0.6s real time
	var final_timer := get_tree().create_timer(0.6, true, false, true)
	final_timer.timeout.connect(_finish_boss_death)

func _finish_boss_death() -> void:
	Engine.time_scale = 1.0

	# Fullscreen flash
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 40
	var flash_rect := ColorRect.new()
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.85)
	flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash_rect)
	get_tree().root.add_child(flash_layer)
	var ftw := flash_rect.create_tween()
	ftw.tween_property(flash_rect, "color:a", 0.0, 0.25)
	ftw.tween_callback(flash_layer.queue_free)

	# Final large explosion
	_spawn_boss_explosion(global_position, true)

	# XP gems spray outward
	_spawn_xp_burst()

	# Remove boss bar with slide-out
	_remove_boss_bar()

	emit_signal("died_signal")
	_sprite.play("death")

func _spawn_boss_explosion(pos: Vector2, large: bool = false) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return
	var sparks := GPUParticles2D.new()
	sparks.global_position = pos
	sparks.amount = 30 if large else 12
	sparks.lifetime = 0.5 if large else 0.3
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 60.0 if large else 30.0
	mat.initial_velocity_max = 180.0 if large else 80.0
	mat.gravity = Vector3(0, 120, 0)
	mat.scale_min = 3.0 if large else 1.5
	mat.scale_max = 7.0 if large else 3.0
	mat.color = Color(0.9, 0.1, 0.1)
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	sparks.texture = ImageTexture.create_from_image(img)
	sparks.process_material = mat
	var cmat := CanvasItemMaterial.new()
	cmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = cmat
	effects.add_child(sparks)
	var cleanup := Timer.new()
	cleanup.wait_time = 1.5
	cleanup.one_shot = true
	cleanup.timeout.connect(sparks.queue_free)
	sparks.add_child(cleanup)
	cleanup.start()

func _spawn_xp_burst() -> void:
	var pickups := get_tree().get_first_node_in_group("pickups_container")
	if not pickups:
		return
	const XP_GEM_SCENE := preload("res://scenes/pickups/xp_gem.tscn")
	var gem_count := 10
	for i in range(gem_count):
		var gem := XP_GEM_SCENE.instantiate()
		gem.xp_value = 5
		var angle := TAU * float(i) / float(gem_count)
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * randf_range(20.0, 60.0)
		pickups.add_child(gem)

func _remove_boss_bar() -> void:
	if not is_instance_valid(_boss_bar_layer):
		return
	var tw := _boss_bar_layer.create_tween()
	tw.tween_property(_boss_bar_layer, "offset", Vector2(0.0, -80.0), 0.4)
	tw.tween_callback(_boss_bar_layer.queue_free)
