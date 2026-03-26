extends Node2D

var particle_color: Color = Color(0.9, 0.3, 0.1)

func _ready() -> void:
	_create_particles()
	var timer := get_tree().create_timer(2.5)
	await timer.timeout
	if is_instance_valid(self):
		queue_free()

func _create_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.amount = 14
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 160.0
	mat.gravity = Vector3(0, 250, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = particle_color

	# Fade out over lifetime
	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(particle_color.r, particle_color.g, particle_color.b, 1.0))
	color_ramp.set_color(1, Color(particle_color.r, particle_color.g, particle_color.b, 0.0))
	mat.color_ramp = GradientTexture1D.new()
	mat.color_ramp.gradient = color_ramp

	# Square pixel texture
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(img)
	particles.process_material = mat

	# Additive blend for glow
	var canvas_mat := CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = canvas_mat

	add_child(particles)

	# Second burst: smaller secondary particles
	var particles2 := GPUParticles2D.new()
	particles2.amount = 8
	particles2.lifetime = 0.6
	particles2.one_shot = true
	particles2.explosiveness = 0.9
	particles2.emitting = true

	var mat2 := ParticleProcessMaterial.new()
	mat2.direction = Vector3(0, -1, 0)
	mat2.spread = 180.0
	mat2.initial_velocity_min = 20.0
	mat2.initial_velocity_max = 60.0
	mat2.gravity = Vector3(0, 150, 0)
	mat2.scale_min = 1.0
	mat2.scale_max = 3.0
	mat2.color = Color(1.0, 0.9, 0.5, 0.8)

	var img2 := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	img2.fill(Color.WHITE)
	particles2.texture = ImageTexture.create_from_image(img2)
	particles2.process_material = mat2
	particles2.material = canvas_mat
	add_child(particles2)
