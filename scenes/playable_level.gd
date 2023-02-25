extends Level

class_name PlayableLevel

@onready var _player = $Player
@onready var _grapnel = $Grapnel
@onready var _screens = $Screens

@export var start_at_screen: Screen
@export var start_at_spawn: Marker2D
@export var end_cutscenes = false : set = _set_end_cutscenes

var _cam_states: Array[CameraState]
var _active_screens = []
var _active_screen: Screen


func _ready():
	followed_node = _player
	
	for node in _screens.get_children():
		if node is Screen:
			node.set_level(self)

	camera.position_smoothing_enabled = false
	
	var screen = start_at_screen
	if screen == null:
		screen = _screens.get_child(0)

	screen.cutscenes_played = end_cutscenes
	screen.load_as_first(_player, start_at_spawn, end_cutscenes)
	call_deferred("finish_prev_screens", screen)
	
	if followed_node != null:
		camera.position = followed_node.position
	
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_set_camera_smoothing"))
	add_child(timer)
	timer.start()


func _set_camera_smoothing():
	camera.position_smoothing_enabled = true


func _set_end_cutscenes(value: bool):
	end_cutscenes = value
	if _active_screen != null:
		_active_screen.cutscenes_played = true


func finish_prev_screens(screen: Screen):
	for i in screen.get_index():
		_screens.get_child(i).finish()


func switch_to_screen(screen: Screen):
	#print("Switched to screen ", screen.name)
	_active_screen = screen
	screen.flush_blockers()
	screen.active = true
	end_cutscenes = screen.cutscenes_played
	_player.spawnpoint = screen.get_closest_spawn(_player.global_position)


func set_active_screen(screen: Screen):
	screen.active = true
	_grapnel.retract()

	add_cam_state(screen.cam_state)
	_active_screens.append(screen)
	switch_to_screen(screen)


func set_inactive_screen(screen: Screen):
	screen.active = false
	
	remove_cam_state(screen.cam_state)
	
	var index = _active_screens.find(screen)
	_active_screens.remove_at(index)
	if index == _active_screens.size() and index != 0:
		switch_to_screen(_active_screens[-1])


func set_cam_state(state: CameraState):
	var edge_1 = state.limits.position
	var edge_2 = state.limits.end
	camera.limit_left = int(edge_1.x)
	camera.limit_top = int(edge_1.y)
	camera.limit_right = int(edge_2.x)
	camera.limit_bottom = int(edge_2.y)
	camera_offset = state.offset


func add_cam_state(state: CameraState):
	_cam_states.append(state)
	set_cam_state(state)


func remove_cam_state(state: CameraState):
	var index = _cam_states.find(state)
	_cam_states.remove_at(index)
	if index == _cam_states.size() and index != 0:
		set_cam_state(_cam_states[-1])


func get_player() -> Player:
	return _player


func get_save_data():
	return {
		'level': scene_file_path,
		'screen': get_path_to(_active_screen) if _active_screen != null else &'',
		'spawn': get_path_to(_player.spawnpoint) if _player.spawnpoint != null else &'',
		'end_cutscenes': end_cutscenes
	}
