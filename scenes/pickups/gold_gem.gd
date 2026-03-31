extends Area2D

var gold_value: int = 1
var _is_attracted: bool = false
var _is_collecting: bool = false
var _player_ref: Node2D = null
var _attract_speed: float = 80.0
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("gold_gem")
	collision_layer = 8  # Pickups
	collision_mask = 0

	_setup_sprite()
	call_deferred("_setup_collision")
	call_deferred("_check_initial_attraction")

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	# Pick one of the 4 coin frames randomly for visual variety.
	var frame := randi_range(1, 4)
	var tex: Texture2D = load("res://assets/items/coin/coin_%d.png" % frame)
	_sprite.texture = tex
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Subtle golden glow via additive material.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	_sprite.material = mat

	add_child(_sprite)

	# Bob tween — slightly faster than XP gems (0.45s) so they feel distinct.
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_sprite, "position:y", -3.0, 0.45).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sprite, "position:y", 3.0, 0.45).set_ease(Tween.EASE_IN_OUT)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func _check_initial_attraction() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p := players[0] as Node2D
	if global_position.distance_to(p.global_position) <= p.pickup_range + 10.0:
		attract_to(p)

func attract_to(target: Node2D) -> void:
	_is_attracted = true
	_player_ref = target

func _physics_process(delta: float) -> void:
	if not _is_attracted or not is_instance_valid(_player_ref) or _is_collecting:
		return

	var dir: Vector2 = _player_ref.global_position - global_position
	var dist := dir.length()

	if dist < 8.0:
		_is_collecting = true
		_collect()
		return

	_attract_speed = lerp(_attract_speed, 600.0, delta * 3.0)
	global_position += dir.normalized() * _attract_speed * delta

func _collect() -> void:
	collision_layer = 0

	SFX.play("gold_pickup", 0.06)
	Progression.add_run_gold(gold_value)

	# Golden spark burst.
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var sparks := GPUParticles2D.new()
		sparks.global_position = global_position
		sparks.amount = 8
		sparks.lifetime = 0.28
		sparks.one_shot = true
		sparks.explosiveness = 0.95
		sparks.emitting = true

		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 35.0
		mat.initial_velocity_max = 85.0
		mat.gravity = Vector3(0, 80, 0)
		mat.scale_min = 1.5
		mat.scale_max = 3.0
		mat.color = Color(1.0, 0.82, 0.15)

		var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		sparks.texture = ImageTexture.create_from_image(img)
		sparks.process_material = mat

		var canvas_mat := CanvasItemMaterial.new()
		canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sparks.material = canvas_mat
		effects.add_child(sparks)

		var cleanup := Timer.new()
		cleanup.wait_time = 1.0
		cleanup.one_shot = true
		cleanup.timeout.connect(sparks.queue_free)
		sparks.add_child(cleanup)
		cleanup.start()

	# Bounce-then-vanish.
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.8, 1.8), 0.06)
	tween.tween_property(_sprite, "scale", Vector2(0.0, 0.0), 0.09)
	tween.tween_callback(queue_free)
