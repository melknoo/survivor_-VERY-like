extends "res://scenes/enemies/base_enemy.gd"

var _phase_offset: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	enemy_type = "bat"
	max_hp = 8.0
	move_speed = 150.0
	damage = 5.0
	xp_value = 2
	knockback_resistance = 0.0
	particle_color = Color(0.5, 0.1, 0.85)
	_phase_offset = randf() * TAU
	super._ready()
	scale = Vector2(0.65, 0.65)

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var path := "res://assets/enemies/Enemy Sprites 48x48/Enemy_015.png"
	# Row 0: fly loop (4 frames)
	_add_animation_row(frames, "idle", path, 4, 48, 48, 10.0, true, 0)
	_add_animation_row(frames, "walk", path, 4, 48, 48, 12.0, true, 0)
	# Row 1: faster flap for hurt
	_add_animation_row(frames, "hurt", path, 4, 48, 48, 14.0, false, 1)
	# Row 4: death/squash
	_add_animation_row(frames, "death", path, 4, 48, 48, 10.0, false, 4)

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
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)

func _setup_contact_area() -> void:
	_contact_area = Area2D.new()
	_contact_area.collision_layer = 2
	_contact_area.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	col.shape = shape
	_contact_area.add_child(col)
	_contact_area.body_entered.connect(_on_contact_body_entered)
	add_child(_contact_area)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return

	_time += delta
	var player := players[0] as Node2D
	var dir := (player.global_position - global_position).normalized()
	var perpendicular := Vector2(-dir.y, dir.x)
	var sine_offset := sin(_time * 5.0 + _phase_offset) * 25.0

	velocity = dir * move_speed + perpendicular * sine_offset + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, delta * 420.0)

	if dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0

	move_and_slide()
