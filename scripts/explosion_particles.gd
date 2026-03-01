extends Node2D
class_name ExplosionParticles

@export var lifetime := 0.38
@export var particle_count := 18
@export var speed_min := 85.0
@export var speed_max := 250.0
@export var drag := 2.4
@export var gravity := 140.0

var _age := 0.0
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("combat_vfx")
	_rng.randomize()
	_particles.clear()
	for _index in range(max(1, particle_count)):
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(speed_min, speed_max)
		var particle_color := Color(1.0, _rng.randf_range(0.48, 0.9), _rng.randf_range(0.14, 0.32), 1.0)
		_particles.append({
			"position": Vector2.ZERO,
			"velocity": Vector2.RIGHT.rotated(angle) * speed,
			"radius": _rng.randf_range(1.2, 3.1),
			"color": particle_color
		})

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	for i in range(_particles.size()):
		var velocity: Vector2 = _particles[i]["velocity"]
		velocity.y += gravity * delta
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta * 100.0)
		var position_now: Vector2 = _particles[i]["position"] + velocity * delta
		_particles[i]["velocity"] = velocity
		_particles[i]["position"] = position_now

	queue_redraw()

func _draw() -> void:
	var fade := 1.0 - clampf(_age / lifetime, 0.0, 1.0)
	for particle in _particles:
		var particle_position: Vector2 = particle["position"]
		var particle_radius: float = particle["radius"]
		var particle_color: Color = particle["color"]
		particle_color.a *= fade
		draw_circle(particle_position, particle_radius, particle_color)
