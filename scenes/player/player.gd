extends CharacterBody2D

signal died
signal level_up(new_level: int)
signal hp_changed(current_hp: int, max_hp: int)
signal xp_changed(current_xp: int, required_xp: int)
signal level_changed(new_level: int)

@export var move_speed: float = 200.0
@export var max_hp: int = 100
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var pickup_range: float = 80.0
@export var char_col: int = 0  # 0-6, welcher Charakter aus rogues.png
@export var char_row: int = 0  # 0-6, welche Zeile aus rogues.png

var current_hp: int
var is_dead: bool = false
var is_invincible: bool = false
var _is_walking: bool = false

var current_level: int = 1
var current_xp: int = 0
var required_xp: int = 10
const BASE_XP: float = 10.0

var _sprite: Sprite2D
var _bob_tween: Tween
var _invincibility_timer: Timer
var _pickup_area: Area2D
var _dust_particles: GPUParticles2D
var _attack_manager: Node

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")

	collision_layer = 1
	collision_mask = 0

	_setup_collision()
	_setup_sprite()
	_setup_pickup_area()
	_setup_invincibility_timer()
	_setup_dust_particles()
	_setup_attack_manager()

	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("xp_changed", current_xp, required_xp)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 16.0
	col.shape = shape
	add_child(col)

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	var texture: Texture2D = load("res://assets/Characters/rogues.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(char_col * 32, char_row * 32, 32, 32)
	_sprite.texture = atlas
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	_start_idle_bob()

func _start_idle_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", -2.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_sprite, "position:y", 2.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _start_walk_bob() -> void:
	if _bob_tween:
		_bob_tween.kill()
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", -3.0, 0.18).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_sprite, "position:y", 3.0, 0.18).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _setup_pickup_area() -> void:
	_pickup_area = Area2D.new()
	_pickup_area.collision_layer = 0
	_pickup_area.collision_mask = 8  # Layer 4 (Pickups) = bit 3 = 8

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = pickup_range
	col.shape = shape
	_pickup_area.add_child(col)

	_pickup_area.area_entered.connect(_on_pickup_area_entered)
	add_child(_pickup_area)

func _setup_invincibility_timer() -> void:
	_invincibility_timer = Timer.new()
	_invincibility_timer.wait_time = 0.5
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)

func _setup_dust_particles() -> void:
	_dust_particles = GPUParticles2D.new()
	_dust_particles.amount = 8
	_dust_particles.lifetime = 0.3
	_dust_particles.emitting = false
	_dust_particles.position = Vector2(0, 10)
	_dust_particles.z_index = -1

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 35.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = Color(0.55, 0.45, 0.28, 0.6)

	# Small square particle texture
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_dust_particles.texture = ImageTexture.create_from_image(img)
	_dust_particles.process_material = mat
	add_child(_dust_particles)

func _setup_attack_manager() -> void:
	_attack_manager = Node.new()
	_attack_manager.name = "AttackManager"
	_attack_manager.set_script(preload("res://scenes/attacks/attack_manager.gd"))
	add_child(_attack_manager)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if dir.length_squared() > 0.0:
		dir = dir.normalized()
		velocity = dir * move_speed
		_dust_particles.emitting = true
		if dir.x != 0.0:
			_sprite.flip_h = dir.x < 0.0
		if not _is_walking:
			_is_walking = true
			_start_walk_bob()
	else:
		velocity = Vector2.ZERO
		_dust_particles.emitting = false
		if _is_walking:
			_is_walking = false
			_start_idle_bob()

	move_and_slide()

func take_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return

	current_hp -= int(amount)
	current_hp = max(0, current_hp)
	emit_signal("hp_changed", current_hp, max_hp)

	is_invincible = true
	_invincibility_timer.start()
	_blink()

	var cam := get_tree().get_first_node_in_group("camera")
	if cam:
		cam.shake(6.0, 0.4)

	if current_hp <= 0:
		_die()

func _blink() -> void:
	var tween := create_tween()
	tween.set_loops(5)
	tween.tween_property(_sprite, "modulate:a", 0.15, 0.05)
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.05)

func _on_invincibility_timeout() -> void:
	is_invincible = false
	_sprite.modulate.a = 1.0

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= required_xp:
		current_xp -= required_xp
		_do_level_up()
	emit_signal("xp_changed", current_xp, required_xp)

func _do_level_up() -> void:
	current_level += 1
	required_xp = int(BASE_XP * float(current_level) * 1.2)
	attack_damage *= 1.05
	move_speed = min(move_speed * 1.05, 500.0)

	emit_signal("level_up", current_level)
	emit_signal("level_changed", current_level)

	var cam := get_tree().get_first_node_in_group("camera")
	if cam:
		cam.shake(4.0, 0.3)

func _die() -> void:
	is_dead = true
	set_physics_process(false)
	_dust_particles.emitting = false
	if _bob_tween:
		_bob_tween.kill()

	# Fade out
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.5)

	emit_signal("died")

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("xp_gem"):
		area.attract_to(self)
