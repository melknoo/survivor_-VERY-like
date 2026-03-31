extends CharacterBody2D

signal died_signal

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var xp_value: int = 5
@export var gold_value: int = 1
@export var gold_drop_chance: float = 0.4
@export var particle_color: Color = Color(0.9, 0.3, 0.1)
@export var enemy_type: String = "skeleton"
@export var knockback_resistance: float = 0.0

const XP_GEM_SCENE := preload("res://scenes/pickups/xp_gem.tscn")
const GOLD_GEM_SCENE := preload("res://scenes/pickups/gold_gem.tscn")
const DEATH_PARTICLES_SCENE := preload("res://scenes/effects/death_particles.tscn")
const DAMAGE_NUMBER_SCENE := preload("res://scenes/effects/damage_number.tscn")

var current_hp: float
var _is_dead: bool = false
var _knockback: Vector2 = Vector2.ZERO

var _sprite: AnimatedSprite2D
var _health_bar_fill: ColorRect
var _health_bar_container: Node2D
var _contact_area: Area2D
var _damage_cooldown: Timer
var _hit_flash_timer: Timer
var _shader_material: ShaderMaterial

func _ready() -> void:
	add_to_group("enemies")
	current_hp = max_hp

	collision_layer = 2
	collision_mask = 0

	_setup_sprite()
	_setup_collision()
	_setup_contact_area()
	_setup_health_bar()
	_setup_timers()

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	# Skeleton1 idle: 192x32 → 6 frames at 32x32
	_add_animation(frames, "idle",
		"res://assets/enemies/Enemy_Animations_Set/enemies-skeleton1_idle.png",
		6, 32, 32, 6.0, true)

	# Skeleton1 movement: 320x32 → 10 frames at 32x32
	_add_animation(frames, "walk",
		"res://assets/enemies/Enemy_Animations_Set/enemies-skeleton1_movement.png",
		10, 32, 32, 10.0, true)

	# Skeleton1 take_damage: 160x32 → 5 frames at 32x32
	_add_animation(frames, "hurt",
		"res://assets/enemies/Enemy_Animations_Set/enemies-skeleton1_take_damage.png",
		5, 32, 32, 12.0, false)

	# Skeleton1 death: 544x32 → 17 frames at 32x32
	_add_animation(frames, "death",
		"res://assets/enemies/Enemy_Animations_Set/enemies-skeleton1_death.png",
		17, 32, 32, 15.0, false)

	_sprite.sprite_frames = frames
	_sprite.animation = "walk"
	_sprite.play()
	_sprite.animation_finished.connect(_on_animation_finished)

	# Set up hit flash shader
	_shader_material = ShaderMaterial.new()
	var shader := load("res://scenes/effects/hit_flash.gdshader")
	_shader_material.shader = shader
	_sprite.material = _shader_material

	add_child(_sprite)

func _add_animation_row(frames: SpriteFrames, anim_name: String, path: String,
		frame_count: int, fw: int, fh: int, speed: float, loop: bool, row: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		for i in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * fw, row * fh, fw, fh)
			frames.add_frame(anim_name, atlas)
	else:
		var img := Image.create(fw, fh, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.8, 0.2, 0.2))
		frames.add_frame(anim_name, ImageTexture.create_from_image(img))

func _add_animation(frames: SpriteFrames, anim_name: String, path: String,
		frame_count: int, fw: int, fh: int, speed: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)

	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		for i in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame(anim_name, atlas)
	else:
		# Placeholder single frame
		# TODO: Replace placeholder
		var img := Image.create(fw, fh, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.8, 0.2, 0.2))
		var placeholder_tex := ImageTexture.create_from_image(img)
		frames.add_frame(anim_name, placeholder_tex)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 14.0
	col.shape = shape
	add_child(col)

func _setup_contact_area() -> void:
	_contact_area = Area2D.new()
	_contact_area.collision_layer = 2
	_contact_area.collision_mask = 1  # Detect Player (layer 1)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	_contact_area.add_child(col)
	_contact_area.body_entered.connect(_on_contact_body_entered)
	add_child(_contact_area)

func _setup_health_bar() -> void:
	_health_bar_container = Node2D.new()
	_health_bar_container.position = Vector2(-16, -20)
	_health_bar_container.visible = false

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.12)
	bg.size = Vector2(32, 2)
	_health_bar_container.add_child(bg)

	# Fill
	_health_bar_fill = ColorRect.new()
	_health_bar_fill.color = Color(0.9, 0.15, 0.1)
	_health_bar_fill.size = Vector2(32, 2)
	_health_bar_container.add_child(_health_bar_fill)

	add_child(_health_bar_container)

func _setup_timers() -> void:
	_damage_cooldown = Timer.new()
	_damage_cooldown.wait_time = 0.5
	_damage_cooldown.one_shot = true
	add_child(_damage_cooldown)

	_hit_flash_timer = Timer.new()
	_hit_flash_timer.wait_time = 0.15
	_hit_flash_timer.one_shot = true
	_hit_flash_timer.timeout.connect(_on_hit_flash_end)
	add_child(_hit_flash_timer)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	var player := players[0] as Node2D
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, delta * 420.0)

	# Flip sprite based on movement direction
	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0

	move_and_slide()

func apply_knockback(direction: Vector2, force: float) -> void:
	_knockback = direction * force * (1.0 - knockback_resistance)

func take_damage(amount: float) -> void:
	if _is_dead:
		return

	current_hp -= amount
	current_hp = max(0.0, current_hp)

	# Show health bar with tween
	_health_bar_container.visible = true
	var tween := create_tween()
	tween.tween_property(_health_bar_fill, "size:x", 32.0 * (current_hp / max_hp), 0.15)

	SFX.play("enemy_hit", 0.1, -4.0)

	# Hit flash
	_trigger_hit_flash()

	# Hurt animation
	_sprite.play("hurt")

	# Spawn damage number
	_spawn_damage_number(amount)

	if current_hp <= 0.0:
		_die()

func _trigger_hit_flash() -> void:
	_shader_material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_timer.start()

func _on_hit_flash_end() -> void:
	var tween := create_tween()
	tween.tween_method(
		func(v: float) -> void: _shader_material.set_shader_parameter("flash_amount", v),
		1.0, 0.0, 0.1
	)

func _spawn_damage_number(amount: float) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return
	var dn := DAMAGE_NUMBER_SCENE.instantiate()
	dn.global_position = global_position + Vector2(randf_range(-8, 8), -20)
	effects.add_child(dn)
	dn.setup(int(amount))

func _die() -> void:
	_is_dead = true
	set_physics_process(false)
	collision_layer = 0
	_contact_area.monitoring = false

	SFX.play("enemy_die", 0.12)
	emit_signal("died_signal")

	# Notify kill counter
	var gw := get_tree().get_first_node_in_group("game_world")
	if gw:
		gw.increment_kill_count()

	# Screenshake
	var cam := get_tree().get_first_node_in_group("camera")
	if cam:
		cam.shake(3.0, 0.2)

	# Gold drop (chance-based physical gem)
	if randf() < gold_drop_chance:
		_spawn_gold_gem()

	# Spawn XP gem
	_spawn_xp_gem()

	# Death particles
	_spawn_death_particles()

	# Play death animation then free
	_sprite.play("death")

func _on_animation_finished() -> void:
	if _sprite.animation == "death":
		call_deferred("queue_free")
	elif _sprite.animation == "hurt" and not _is_dead:
		_sprite.play("walk")

func _spawn_gold_gem() -> void:
	var pickups := get_tree().get_first_node_in_group("pickups_container")
	if not pickups:
		return
	var gem := GOLD_GEM_SCENE.instantiate()
	gem.gold_value = gold_value
	gem.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
	call_deferred("_add_gold_gem", pickups, gem)

func _add_gold_gem(container: Node, gem: Node) -> void:
	container.add_child(gem)

func _spawn_xp_gem() -> void:
	var pickups := get_tree().get_first_node_in_group("pickups_container")
	if not pickups:
		return
	var gem := XP_GEM_SCENE.instantiate()
	gem.xp_value = xp_value
	gem.global_position = global_position
	pickups.add_child(gem)

func _spawn_death_particles() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return
	var particles := DEATH_PARTICLES_SCENE.instantiate()
	particles.global_position = global_position
	particles.particle_color = particle_color
	effects.add_child(particles)

func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _damage_cooldown.is_stopped():
		body.take_damage(damage)
		_damage_cooldown.start()
