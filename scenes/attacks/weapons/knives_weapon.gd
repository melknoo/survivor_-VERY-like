extends BaseWeapon

# Level stats: melee stab radius, cooldown (s), effective damage
const LEVEL_STATS: Array = [
	{"radius": 110.0, "cooldown": 0.95, "damage": 14.0},
	{"radius": 120.0, "cooldown": 0.90, "damage": 16.0},
	{"radius": 130.0, "cooldown": 0.85, "damage": 18.0},
	{"radius": 140.0, "cooldown": 0.80, "damage": 20.0},
	{"radius": 150.0, "cooldown": 0.75, "damage": 22.0},
	{"radius": 160.0, "cooldown": 0.70, "damage": 24.0},
	{"radius": 170.0, "cooldown": 0.65, "damage": 26.0},
	{"radius": 180.0, "cooldown": 0.60, "damage": 28.0},
]

func _ready() -> void:
	weapon_id = "weapon_knives"
	weapon_name = "Klingen"
	base_damage = 10.0
	base_cooldown = 1.0
	super._ready()

func _get_stats_for_level(level: int) -> Dictionary:
	return LEVEL_STATS[clampi(level - 1, 0, LEVEL_STATS.size() - 1)]

func activate() -> void:
	var stats := _get_stats_for_level(current_level)
	var radius: float = stats["radius"]
	var dmg := get_effective_damage()

	var target := _find_primary_target(radius)
	if not target:
		return
	_perform_stab(radius, dmg, target)
	SFX.play("knife_throw")

func _find_primary_target(max_radius: float) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist_sq := max_radius * max_radius
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq := _player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy
	return nearest

func _perform_stab(radius: float, dmg: float, primary: Node2D) -> void:
	var dir_forward := (primary.global_position - _player.global_position).normalized()
	_spawn_stab_vfx(dir_forward, radius)
	_spawn_stab_hitbox(dir_forward, radius * 0.82, 28.0, dmg)

func _spawn_stab_hitbox(dir_forward: Vector2, tip_distance: float, hit_radius: float, dmg: float) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return

	var hitbox := Area2D.new()
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2
	hitbox.monitoring = true
	hitbox.global_position = _player.global_position + dir_forward * tip_distance

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = hit_radius
	col.shape = shape
	hitbox.add_child(col)

	var hit_once: Dictionary = {}
	hitbox.body_entered.connect(_on_stab_hitbox_body_entered.bind(dmg, dir_forward, hit_once))
	effects.add_child(hitbox)

	var cleanup := Timer.new()
	cleanup.wait_time = 0.10
	cleanup.one_shot = true
	cleanup.timeout.connect(hitbox.queue_free)
	hitbox.add_child(cleanup)
	cleanup.start()

func _on_stab_hitbox_body_entered(body: Node2D, dmg: float, dir_forward: Vector2, hit_once: Dictionary) -> void:
	if not is_instance_valid(body) or not body.is_in_group("enemies"):
		return
	var eid: int = body.get_instance_id()
	if hit_once.has(eid):
		return
	hit_once[eid] = true
	if body.has_method("take_damage"):
		body.take_damage(dmg)
	if body.has_method("apply_knockback"):
		body.apply_knockback(dir_forward, 35.0)
	SFX.play("knife_hit")

func _spawn_stab_vfx(dir_forward: Vector2, radius: float) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return

	# Thin stab line: from player outward, like a dagger thrust.
	var stab := Line2D.new()
	stab.z_index = 12
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	stab.material = mat
	# Thick bright core + thin trail gives a sharp blade silhouette.
	stab.width_curve = _make_stab_width_curve()
	stab.gradient = _make_stab_gradient()
	stab.points = PackedVector2Array([
		_player.global_position + dir_forward * 12.0,
		_player.global_position + dir_forward * radius,
	])
	effects.add_child(stab)

	# Snap in, then fade — feels like a quick poke.
	var tw := stab.create_tween()
	tw.tween_interval(0.04)
	tw.tween_property(stab, "modulate:a", 0.0, 0.09)
	tw.tween_callback(stab.queue_free)

	# Small metallic spark burst at tip.
	var sparks := GPUParticles2D.new()
	sparks.global_position = _player.global_position + dir_forward * radius
	sparks.amount = 8
	sparks.lifetime = 0.18
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(dir_forward.x, dir_forward.y, 0.0)
	pmat.spread = 35.0
	pmat.initial_velocity_min = 40.0
	pmat.initial_velocity_max = 90.0
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 1.5
	pmat.scale_max = 3.0
	# Warm gold → orange metallic sparks.
	pmat.color = Color(1.0, 0.78, 0.2, 1.0)
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	sparks.texture = ImageTexture.create_from_image(img)
	sparks.process_material = pmat
	var smat := CanvasItemMaterial.new()
	smat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = smat
	effects.add_child(sparks)

	var cleanup := Timer.new()
	cleanup.wait_time = 0.6
	cleanup.one_shot = true
	cleanup.timeout.connect(sparks.queue_free)
	sparks.add_child(cleanup)
	cleanup.start()

func _make_stab_width_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.3))   # thin at hilt
	c.add_point(Vector2(0.35, 1.0))  # widest at shoulder
	c.add_point(Vector2(1.0, 0.05))  # sharp tip
	return c

func _make_stab_gradient() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	g.add_point(0.15, Color(0.9, 0.97, 1.0, 0.95))
	g.add_point(0.6, Color(0.7, 0.85, 1.0, 0.8))
	g.set_color(g.get_point_count() - 1, Color(0.5, 0.6, 1.0, 0.0))
	return g
