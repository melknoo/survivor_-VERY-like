extends "res://scenes/enemies/base_enemy.gd"

@export var can_split: bool = true
@export var is_small: bool = false

var _squash_tween: Tween

func _ready() -> void:
	enemy_type = "slime"
	if is_small:
		max_hp = 15.0
		move_speed = 75.0
		damage = 8.0
		xp_value = 3
		gold_value = 1
		gold_drop_chance = 0.25
		knockback_resistance = 0.3
		particle_color = Color(0.3, 1.0, 0.2)
	else:
		max_hp = 45.0
		move_speed = 45.0
		damage = 15.0
		xp_value = 8
		gold_value = 2
		gold_drop_chance = 0.6
		knockback_resistance = 0.7
		particle_color = Color(0.1, 0.85, 0.1)

	super._ready()

	if is_small:
		scale = Vector2(0.7, 0.7)
	else:
		scale = Vector2(1.3, 1.3)
		_sprite.modulate.a = 0.85

	_start_squash_animation()

func _setup_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	var path := "res://assets/enemies/Enemy Sprites 48x48/Enemy_043.png"
	_add_animation_row(frames, "idle", path, 4, 48, 48, 6.0, true, 0)
	_add_animation_row(frames, "walk", path, 4, 48, 48, 6.0, true, 0)
	_add_animation_row(frames, "hurt", path, 4, 48, 48, 12.0, false, 1)
	_add_animation_row(frames, "death", path, 4, 48, 48, 8.0, false, 4)

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
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

func _setup_contact_area() -> void:
	_contact_area = Area2D.new()
	_contact_area.collision_layer = 2
	_contact_area.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	col.shape = shape
	_contact_area.add_child(col)
	_contact_area.body_entered.connect(_on_contact_body_entered)
	add_child(_contact_area)

func _start_squash_animation() -> void:
	if _squash_tween:
		_squash_tween.kill()
	var spd := 1.5 if is_small else 1.0
	_squash_tween = create_tween().set_loops()
	_squash_tween.tween_property(_sprite, "scale:y", 1.15, 0.4 / spd).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_squash_tween.tween_property(_sprite, "scale:y", 0.85, 0.4 / spd).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _die() -> void:
	if _squash_tween:
		_squash_tween.kill()
	if can_split and not is_small:
		call_deferred("_spawn_small_slimes")
	super._die()

func _spawn_small_slimes() -> void:
	var container := get_tree().get_first_node_in_group("enemies_container")
	if not container:
		return

	SFX.play("slime_split", 0.08, -2.0)

	# Split effect: green flash on sprite before death
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color(0.3, 1.0, 0.2, 1.0), 0.05)

	for i in range(2):
		var small := preload("res://scenes/enemies/slime_enemy.tscn").instantiate()
		small.can_split = false
		small.is_small = true
		small.global_position = global_position
		container.add_child(small)

		# Jump outward
		var dir := Vector2.RIGHT.rotated(PI * float(i))
		small.apply_knockback(dir, 220.0)

		# Register with spawner for count tracking
		var spawner := get_tree().get_first_node_in_group("enemy_spawner")
		if spawner and spawner.has_method("register_enemy"):
			spawner.register_enemy(small)
