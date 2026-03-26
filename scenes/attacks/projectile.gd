extends Area2D

const SPEED := 420.0
const LIFETIME := 2.2

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var _lifetime: float = 0.0
var _sprite: Sprite2D
var _trail: GPUParticles2D

func _ready() -> void:
	collision_layer = 4  # PlayerProjectiles
	collision_mask = 2   # Enemies

	_setup_collision()
	_setup_sprite()
	_setup_trail()
	body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	add_child(col)

func setup(dir: Vector2, dmg: float) -> void:
	direction = dir
	damage = dmg
	rotation = dir.angle()

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()

	# Glowing orb projectile
	# TODO: Replace placeholder with a proper projectile asset
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	for x in range(10):
		for y in range(10):
			var dx := x - 4.5
			var dy := y - 4.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= 4.5:
				var alpha := 1.0 - (dist / 4.5)
				img.set_pixel(x, y, Color(0.4, 0.9, 1.0, alpha))
	_sprite.texture = ImageTexture.create_from_image(img)

	var light_mat := CanvasItemMaterial.new()
	light_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sprite.material = light_mat
	add_child(_sprite)

func _setup_trail() -> void:
	_trail = GPUParticles2D.new()
	_trail.amount = 10
	_trail.lifetime = 0.2
	_trail.emitting = true
	_trail.z_index = -1

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)  # Behind projectile
	mat.spread = 20.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 30.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(0.3, 0.7, 1.0, 0.6)

	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_trail.texture = ImageTexture.create_from_image(img)
	_trail.process_material = mat

	var light_mat := CanvasItemMaterial.new()
	light_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail.material = light_mat

	add_child(_trail)

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	_lifetime += delta
	if _lifetime >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		_spawn_impact_particles()
		queue_free()

func _spawn_impact_particles() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return

	# Mini spark particles
	var sparks := GPUParticles2D.new()
	sparks.global_position = global_position
	sparks.amount = 8
	sparks.lifetime = 0.25
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = Color(0.5, 0.9, 1.0)

	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	sparks.texture = ImageTexture.create_from_image(img)
	sparks.process_material = mat

	var light_mat := CanvasItemMaterial.new()
	light_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = light_mat

	effects.add_child(sparks)

	# Self-cleaning timer on the sparks node — avoids dangling coroutines
	var cleanup := Timer.new()
	cleanup.wait_time = 1.2
	cleanup.one_shot = true
	cleanup.timeout.connect(sparks.queue_free)
	sparks.add_child(cleanup)
	cleanup.start()
