extends Level

class_name PlayableLevel

onready var _player = $Player
onready var _grapnel = $Grapnel

export var start_at_screen = ""
export var skip_first_cutscene = false

var _cam_limits = []
var _active_screens = []
var _active_screen: Screen

var followed_node = null

var _finished_screen_cutscenes = false


func _ready():
	followed_node = _player
	_player.set_grapnel(_grapnel)
	
	for node in get_children():
		if node is Screen:
			node.set_level(self)

	if not start_at_screen.empty():
		call_deferred("begin_at_screen", start_at_screen, skip_first_cutscene)


func begin_at_screen(name: String, end_cutscenes = false, spawnpoint = Vector2.ZERO):
	camera.smoothing_enabled = false
	get_node(start_at_screen).load_as_first(_player, spawnpoint, end_cutscenes)
	extra_screen_load(name)
	
	for _i in 3:
		yield(get_tree(), "idle_frame")

	camera.smoothing_enabled = true


func extra_screen_load(_name: String):
	pass


func _process(_delta):
	if followed_node != null:
		camera.position = followed_node.position


func switch_to_screen(screen: Screen):
	print("Switched to screen ", screen.name)
	_active_screen = screen
	screen.flush_blockers()
	screen.active = true
	
	# Find spawnpoint closest to player
	var min_dist = INF
	var closest_spawn = null
	for spawn in screen.spawnpoints:
		var dist = (screen.global_position + spawn).distance_to(_player.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_spawn = screen.global_position + spawn

	if closest_spawn != null:
		_player.spawnpoint = closest_spawn


func set_active_screen(screen: Screen):
	screen.active = true
	_grapnel.retract()

	add_cam_limits(screen.get_extents())
	_active_screens.append(screen)
	switch_to_screen(screen)


func set_inactive_screen(screen: Screen):
	screen.active = false
	
	remove_cam_limits(screen.get_extents())
	
	var index = _active_screens.find(screen)
	_active_screens.remove(index)
	if index == _active_screens.size():
		if index == 0:
			print("ERROR: No active screens available (player left playable area)")
		else:
			switch_to_screen(_active_screens[-1])


func set_cam_limits(limits: Rect2):
	var edge_1 = limits.position
	var edge_2 = limits.end
	camera.limit_left = int(edge_1.x)
	camera.limit_top = int(edge_1.y)
	camera.limit_right = int(edge_2.x)
	camera.limit_bottom = int(edge_2.y)


func add_cam_limits(limits: Rect2):
	_cam_limits.append(limits)
	set_cam_limits(limits)


func remove_cam_limits(limits: Rect2):
	var index = _cam_limits.find(limits)
	_cam_limits.remove(index)
	if index == _cam_limits.size():
		if index == 0:
			print("ERROR: No camera limits available (player left playable area)")
		else:
			set_cam_limits(_cam_limits[-1])


func get_player() -> Player:
	return _player


func get_save_data():
	return {
		'level': get_tree().current_scene.filename,
		'screen': _active_screen.name,
		'spawn': _player.spawnpoint,
		'end_cutscenes': _finished_screen_cutscenes
	}
