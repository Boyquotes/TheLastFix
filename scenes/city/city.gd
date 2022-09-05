extends PlayableLevel

onready var _cutscene_player = $CutscenePlayer
onready var _car = $"01/Car"
onready var _car_stand = $"01/Car/CarStandArea"
var _stood_on_car = false


func _ready():
	_cutscene_player.play("intro")


func _physics_process(_delta):
	if _car_stand.get_overlapping_bodies().has(_player) and _player.is_on_floor():
		_stood_on_car = true
		_car.frame = 11
	elif _stood_on_car:
		_car.frame = 12
		_stood_on_car = false


func _on_DeathArea_body_entered(body):
	if body is Player:
		body.position = _active_screen.spawnpoint + _active_screen.position
		_grapnel.retract()
