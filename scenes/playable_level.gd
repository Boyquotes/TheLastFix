extends Level

class_name PlayableLevel

onready var _player = $Player
onready var _grapnel = $Grapnel
onready var _screens = $Screens

export var start_at_screen = ""
export var start_at_spawn = Vector2.ZERO
export var end_cutscenes = false setget _set_end_cutscenes

var _cam_limits = []
var _active_screens = []
var _active_screen: Screen


func _ready():
	followed_node = _player
	_player.set_grapnel(_grapnel)
	
	for node in _screens.get_children():
		if node is Screen:
			node.set_level(self)

	camera.smoothing_enabled = false
	
	if start_at_screen.empty():
		start_at_screen = _screens.get_child(0).name

	var screen = _screens.get_node(start_at_screen)
	screen._cutscenes_played = end_cutscenes
	screen.load_as_first(_player, start_at_spawn, end_cutscenes)
	call_deferred("finish_prev_screens", screen)
	
	if followed_node != null:
		camera.position = followed_node.position
	
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.connect("timeout", self, "_set_camera_smoothing")
	add_child(timer)
	timer.start()


func _set_camera_smoothing():
	camera.smoothing_enabled = true


func _set_end_cutscenes(value: bool):
	end_cutscenes = value
	if _active_screen != null:
		_active_screen._cutscenes_played = true


func finish_prev_screens(screen: Screen):
	for i in screen.get_index() - 1:
		_screens.get_child(i).finish()


func switch_to_screen(screen: Screen):
	#print("Switched to screen ", screen.name)
	_active_screen = screen
	screen.flush_blockers()
	screen.active = true
	end_cutscenes = screen._cutscenes_played
	
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
	if index == _active_screens.size() and index != 0:
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
	if index == _cam_limits.size() and index != 0:
		set_cam_limits(_cam_limits[-1])


func get_player() -> Player:
	return _player


func get_save_data():
	return {
		'level': filename,
		'screen': _active_screen.name if _active_screen != null else '',
		'spawn': _player.spawnpoint,
		'end_cutscenes': end_cutscenes
	}
