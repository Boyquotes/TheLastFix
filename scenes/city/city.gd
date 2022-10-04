extends PlayableLevel

onready var _car = $"01/Car"
onready var _car_stand = $"01/Car/CarStandArea"
var _stood_on_car = false
var _spoke_to_frankie = false


func _ready():
	if start_at_screen.empty():
		followed_node = null
		_cutscene_player.play("intro")
	else:
		camera.drag_margin_h_enabled = true


func cam_follow_player():
	followed_node = _player


func _physics_process(_delta):
	if _car_stand.get_overlapping_bodies().has(_player) and _player.is_on_floor():
		_stood_on_car = true
		_car.frame = 11
	elif _stood_on_car:
		_car.frame = 12
		_stood_on_car = false


func _on_FireHydrant_finished_fixing():
	$"05".block_right = false



func _on_FrankieTalkArea_body_entered(body):
	if body is Player and not _spoke_to_frankie:
		_spoke_to_frankie = true
		_player.go_to($"13/Building/FrankieTalkPos".global_position)
		var error = _player.connect("reached_target", self, "meet_frankie")
		if error != OK:
			print("Error connecting reached_target: ", error)


func meet_frankie():
	_player.disconnect("reached_target", self, "meet_frankie")
	_cutscene_player.play("meet_frankie")
