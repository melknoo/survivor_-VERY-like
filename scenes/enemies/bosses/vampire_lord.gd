extends "res://scenes/enemies/bosses/base_boss.gd"

# Vampire sprite: all sheets are 32px tall, row 0
# idle: 192x32 → 6f  |  movement: 256x32 → 8f
# attack: 512x32 → 16f  |  take_damage: 160x32 → 5f  |  death: 448x32 → 14f

const BLOOD_NOVA_SCENE := preload("res://scenes/enemies/bosses/blood_nova.tscn")
const BAT_SCENE := preload("res://scenes/enemies/bat_enemy.tscn")

# Phase 1 config
const P1_NOVA_COOLDOWN := 4.0
const P1_BAT_COOLDOWN  := 8.0
const P1_BAT_COUNT     := 4
const P1_SPEED         := 55.0

# Phase 2 config
const P2_NOVA_COOLDOWN := 2.5
const P2_BAT_COOLDOWN  := 5.0
const P2_BAT_COUNT     := 6
const P2_SPEED         := 80.0

var _nova_timer: float = P1_NOVA_COOLDOWN
var _bat_timer: float  = P1_BAT_COOLDOWN
var _attack_locked: bool = false  # Freeze during nova animation

# Phase-2 aura
var _aura_area: Area2D
var _aura_timer: float = 0.0
const AURA_TICK := 0.4
const AURA_RADIUS := 80.0
const AURA_DAMAGE := 2.0  # per tick (5 dmg/s at 0.4s tick)

func _ready() -> void:
	boss_name = "Vampire Lord"
	max_hp = 500.0
	move_speed = P1_SPEED
	damage = 25.0
	xp_value = 50
	gold_value = 25
	knockback_resistance = 1.0
	particle_color = Color(0.65, 0.0, 0.1)
	super._ready()
	scale = Vector2(2.0, 2.0)
	_setup_boss_bar()
	_setup_glow()

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var base := "res://assets/enemies/Enemy_Animations_Set/enemies-vampire_"
	_add_animation(frames, "idle",  base + "idle.png",        6,  32, 32, 8.0,  true)
	_add_animation(frames, "walk",  base + "movement.png",    8,  32, 32, 10.0, true)
	_add_animation(frames, "hurt",  base + "take_damage.png", 5,  32, 32, 14.0, false)
	_add_animation(frames, "death", base + "death.png",       14, 32, 32, 12.0, false)
	_add_animation(frames, "attack", base + "attack.png",     16, 32, 32, 20.0, false)

	_sprite.sprite_frames = frames
	_sprite.animation = "walk"
	_sprite.play()
	_sprite.animation_finished.connect(_on_animation_finished)

	_shader_material = ShaderMaterial.new()
	_shader_material.shader = load("res://scenes/effects/hit_flash.gdshader")
	_sprite.material = _shader_material

	add_child(_sprite)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 18.0
	col.shape = shape
	add_child(col)

func _setup_contact_area() -> void:
	_contact_area = Area2D.new()
	_contact_area.collision_layer = 2
	_contact_area.collision_mask = 1
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	_contact_area.add_child(col)
	_contact_area.body_entered.connect(_on_contact_body_entered)
	add_child(_contact_area)

func _setup_glow() -> void:
	# Subtle additive red glow sprite behind the boss
	var glow := Sprite2D.new()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c := 15.5
	for x in range(32):
		for y in range(32):
			var d := Vector2(x - c, y - c).length() / c
			if d <= 1.0:
				img.set_pixel(x, y, Color(0.8, 0.0, 0.0, (1.0 - d) * 0.35))
	glow.texture = ImageTexture.create_from_image(img)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.scale = Vector2(2.5, 3.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.z_index = -1
	add_child(glow)

	# Pulsing glow tween
	var tw := glow.create_tween().set_loops()
	tw.tween_property(glow, "modulate:a", 0.4, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player := players[0] as Node2D

	# Phase 2 aura damage
	if _current_phase == 2 and is_instance_valid(_aura_area):
		_aura_timer -= delta
		if _aura_timer <= 0.0:
			_aura_timer = AURA_TICK
			_tick_aura()

	if not _attack_locked:
		# Movement
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * move_speed + _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, delta * 200.0)
		if dir.x != 0.0:
			_sprite.flip_h = dir.x < 0.0
		move_and_slide()

		# Timers
		_nova_timer -= delta
		if _nova_timer <= 0.0:
			_nova_timer = P2_NOVA_COOLDOWN if _current_phase == 2 else P1_NOVA_COOLDOWN
			_trigger_nova()

		_bat_timer -= delta
		if _bat_timer <= 0.0:
			_bat_timer = P2_BAT_COOLDOWN if _current_phase == 2 else P1_BAT_COOLDOWN
			_spawn_bat_swarm()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func take_damage(amount: float) -> void:
	var was_above_half := current_hp > max_hp * 0.5
	super.take_damage(amount)
	if was_above_half and current_hp <= max_hp * 0.5 and _current_phase == 1:
		_enter_phase_2()

func _trigger_nova() -> void:
	_attack_locked = true
	velocity = Vector2.ZERO
	_sprite.play("attack")

	# Wait for animation wind-up (0.5s worth)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(_fire_nova)

func _fire_nova() -> void:
	if _is_dead:
		_attack_locked = false
		return

	SFX.play("garlic_pulse", 0.05, 2.0)

	var cam := get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(6.0, 0.4)

	var nova := BLOOD_NOVA_SCENE.instantiate()
	nova.global_position = global_position
	nova.target_radius = 280.0 if _current_phase == 2 else 200.0
	nova.nova_damage = 20.0 if _current_phase == 2 else 15.0
	get_tree().get_first_node_in_group("effects_container").add_child(nova)

	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func() -> void: _attack_locked = false)

func _spawn_bat_swarm() -> void:
	var container := get_tree().get_first_node_in_group("enemies_container")
	if not container:
		return
	var spawner := get_tree().get_first_node_in_group("enemy_spawner")
	var count := P2_BAT_COUNT if _current_phase == 2 else P1_BAT_COUNT
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var bat := BAT_SCENE.instantiate()
		bat.global_position = global_position + Vector2(cos(angle), sin(angle)) * 60.0
		container.add_child(bat)
		if spawner and spawner.has_method("register_enemy"):
			spawner.register_enemy(bat)
	SFX.play("bat_screech", 0.05)

func _enter_phase_2() -> void:
	_current_phase = 2
	move_speed = P2_SPEED

	# Visual blink + flash
	var cam := get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(8.0, 0.5)

	SFX.play("lightning_strike", 0.0, 2.0)

	# Red flash
	var tw := _sprite.create_tween()
	tw.tween_property(_sprite, "modulate", Color(2.0, 0.1, 0.1), 0.1)
	tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	tw.tween_property(_sprite, "modulate", Color(2.0, 0.1, 0.1), 0.1)
	tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.3)

	_setup_phase2_aura()

func _setup_phase2_aura() -> void:
	_aura_area = Area2D.new()
	_aura_area.collision_layer = 0
	_aura_area.collision_mask = 1
	_aura_area.monitoring = true
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = AURA_RADIUS / scale.x  # Account for boss scale
	col.shape = shape
	_aura_area.add_child(col)
	add_child(_aura_area)

	# Visual aura ring
	var aura_sprite := Sprite2D.new()
	var size := int(AURA_RADIUS / scale.x) * 2 + 4
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := (size - 1) * 0.5
	for x in range(size):
		for y in range(size):
			var d := Vector2(x - center, y - center).length() / center
			if d <= 1.0:
				var ring := 1.0 - smoothstep(0.7, 1.0, d)
				img.set_pixel(x, y, Color(0.8, 0.0, 0.0, ring * 0.5))
	aura_sprite.texture = ImageTexture.create_from_image(img)
	aura_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	aura_sprite.material = mat

	var atw := aura_sprite.create_tween().set_loops()
	atw.tween_property(aura_sprite, "modulate:a", 0.5, 0.6).set_trans(Tween.TRANS_SINE)
	atw.tween_property(aura_sprite, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	add_child(aura_sprite)

func _tick_aura() -> void:
	if not is_instance_valid(_aura_area):
		return
	for body in _aura_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(AURA_DAMAGE)

func _on_animation_finished() -> void:
	if _sprite.animation == "death":
		call_deferred("queue_free")
	elif _sprite.animation in ["hurt", "attack"] and not _is_dead:
		_sprite.play("walk")
