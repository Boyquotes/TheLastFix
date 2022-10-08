extends Screen

onready var _car = $Car
onready var _car_stand = $Car/CarStandArea
var _stood_on_car = false


func _physics_process(_delta):
	if _car_stand.get_overlapping_bodies().has(_level._player) and _level._player.is_on_floor():
		_stood_on_car = true
		_car.frame = 11
	elif _stood_on_car:
		_car.frame = 12
		_stood_on_car = false


func load_as_first(player, _spawnpoint: Vector2, end_cutscenes: bool):
	var _cutscene_animator = $"../../CutsceneAnimator"
	_cutscene_animator.play("intro")
	_level.followed_node = null
	if end_cutscenes:
		_cutscene_animator.seek(_cutscene_animator.current_animation_length)
		player.play_idle()
		_level.cam_follow_player()
		_level.camera.drag_margin_h_enabled = true


func finish():
	_car.position = Vector2(-83, 18)
	_car.frame_coords = Vector2(4, 1)
	$Car/PlayerPuppet.visible = false
	$Car/Light.enabled = false
	_level.cam_follow_player()
	_level.camera.drag_margin_h_enabled = true
	_cutscenes_played = true
