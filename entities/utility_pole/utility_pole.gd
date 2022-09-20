extends Node2D

class_name UtilityPole

const particle_dist = 5
const gravity = 500

const left_start = Vector2(35, -84)
const right_start = Vector2(1, -84)

export var left_end: Vector2
export var right_end: Vector2

class Particle:
	var position: Vector2
	var init_pos: Vector2
	var prev_pos: Vector2
	var force = Vector2(0, gravity)


var lines = []


func _ready():
	if left_end != Vector2.ZERO:
		create_line(right_start, left_end)
	if right_end != Vector2.ZERO:
		create_line(left_start, right_end)


func create_line(start: Vector2, end: Vector2):
	var particle_count = int(start.distance_to(end) / particle_dist)
	var interval = (end - start) / particle_count
	var line = []

	for i in range(particle_count + 1):
		var particle = Particle.new()
		particle.position = start + i * interval
		particle.prev_pos = particle.position
		particle.init_pos = particle.position
		line.append(particle)

	lines.append(line)


func relax_constraint(particle_1: Particle, particle_2: Particle, fixed = 0):
	# Jakobsen method
	# https://owlree.blog/posts/simulating-a-rope.html
	var dir = (particle_2.position - particle_1.position).normalized()
	var delta = particle_1.position.distance_to(particle_2.position) - particle_dist
	if fixed == 0:
		particle_1.position += delta * dir / 2
		particle_2.position -= delta * dir / 2
	elif fixed == 1:
		particle_2.position -= delta * dir
	elif fixed == 2:
		particle_1.position += delta * dir


func _process(_delta):
	update()


func _physics_process(delta):
	for line in lines:
		for i in range(1, line.size() - 1):
			# Verlet approximation: https://owlree.blog/posts/simulating-a-rope.html
			var particle = line[i]
			particle.prev_pos = particle.position
			particle.position += particle.position - particle.prev_pos + delta * particle.force
		
		relax_constraint(line[0], line[1], 1)
		for i in range(1, line.size() - 2):
			relax_constraint(line[i], line[i + 1])
		relax_constraint(line[line.size() - 2], line[line.size() - 1], 2)


func _draw():
	for line in lines:
		for i in range(1, line.size()):
			var prev_pos = line[i - 1].position
			var new_pos = line[i].position
			prev_pos.y += (line[i - 1].init_pos.y - prev_pos.y) * 0.98
			new_pos.y += (line[i].init_pos.y - new_pos.y) * 0.98
			draw_line(prev_pos, new_pos, Color.blue)
