extends BaseWeapon

const LEVEL_STATS: Array = [
	{"damage":  25.0, "cooldown": 2.0,  "chains": 0, "radius": 300.0, "chain_radius":   0.0},
	{"damage":  30.0, "cooldown": 1.8,  "chains": 0, "radius": 350.0, "chain_radius":   0.0},
	{"damage":  35.0, "cooldown": 1.6,  "chains": 1, "radius": 400.0, "chain_radius": 100.0},
	{"damage":  40.0, "cooldown": 1.4,  "chains": 1, "radius": 400.0, "chain_radius": 120.0},
	{"damage":  50.0, "cooldown": 1.2,  "chains": 2, "radius": 450.0, "chain_radius": 140.0},
	{"damage":  60.0, "cooldown": 1.0,  "chains": 2, "radius": 500.0, "chain_radius": 160.0},
	{"damage":  75.0, "cooldown": 0.85, "chains": 3, "radius": 550.0, "chain_radius": 180.0},
	{"damage": 100.0, "cooldown": 0.70, "chains": 4, "radius": 600.0, "chain_radius": 200.0},
]

func _ready() -> void:
	weapon_id = "weapon_lightning"
	weapon_name = "Kettenblitz"
	base_damage = 25.0
	base_cooldown = 2.0
	super._ready()

func _get_stats_for_level(level: int) -> Dictionary:
	return LEVEL_STATS[clampi(level - 1, 0, LEVEL_STATS.size() - 1)]

func activate() -> void:
	var stats := _get_stats_for_level(current_level)
	var radius: float = stats["radius"]
	var chains: int = stats["chains"]
	var chain_radius: float = stats["chain_radius"]

	var candidates := _enemies_in_radius(_player.global_position, radius)
	if candidates.is_empty():
		return

	var primary := candidates[randi() % candidates.size()] as Node2D
	var from_pos := primary.global_position + Vector2(randf_range(-20.0, 20.0), -680.0)
	SFX.play("lightning_strike")
	_strike(primary, get_effective_damage(), from_pos, true)

	var hit: Array = [primary]
	for _c in range(chains):
		var last := hit[hit.size() - 1] as Node2D
		var next := _find_chain_target(last.global_position, chain_radius, hit)
		if not next:
			break
		SFX.play("lightning_chain", 0.1, -4.0)
		_strike(next, get_effective_damage() * 0.65, last.global_position, false)
		hit.append(next)

func _strike(enemy: Node2D, dmg: float, origin: Vector2, primary: bool) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(dmg)
	var cam := get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(2.0, 0.1)
	_spawn_bolt(origin, enemy.global_position, primary)
	_spawn_flash(enemy.global_position)

func _spawn_bolt(from: Vector2, to: Vector2, primary: bool) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return

	var line := Line2D.new()
	line.width = 3.5 if primary else 2.0
	line.default_color = Color(0.75, 0.90, 1.0, 1.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	line.material = mat
	line.z_index = 10

	var pts := PackedVector2Array()
	pts.append(from)
	var segs := 5 if primary else 3
	for i in range(1, segs):
		var t := float(i) / segs
		var p := from.lerp(to, t)
		p.x += randf_range(-28.0, 28.0)
		pts.append(p)
	pts.append(to)
	line.points = pts

	effects.add_child(line)

	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)

func _spawn_flash(pos: Vector2) -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return
	var sparks := GPUParticles2D.new()
	sparks.global_position = pos
	sparks.amount = 8
	sparks.lifetime = 0.22
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.spread = 180.0
	pmat.initial_velocity_min = 55.0
	pmat.initial_velocity_max = 130.0
	pmat.gravity = Vector3(0, 80, 0)
	pmat.scale_min = 2.0
	pmat.scale_max = 4.0
	pmat.color = Color(0.9, 0.95, 1.0)
	var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	sparks.texture = ImageTexture.create_from_image(img)
	sparks.process_material = pmat
	var smat := CanvasItemMaterial.new()
	smat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparks.material = smat
	effects.add_child(sparks)
	var cleanup := Timer.new()
	cleanup.wait_time = 0.8
	cleanup.one_shot = true
	cleanup.timeout.connect(sparks.queue_free)
	sparks.add_child(cleanup)
	cleanup.start()

func _enemies_in_radius(origin: Vector2, radius: float) -> Array:
	var result: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and origin.distance_squared_to(e.global_position) <= radius * radius:
			result.append(e)
	return result

func _find_chain_target(origin: Vector2, radius: float, exclude: Array) -> Node2D:
	var best: Node2D = null
	var best_d := radius * radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or exclude.has(e):
			continue
		var d := origin.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
