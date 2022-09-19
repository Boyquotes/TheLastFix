extends Node2D

class_name Fixable

var _ready_to_fix = false
var _player: Player

onready var _player_puppet = $PlayerPuppet
onready var _fix_animation = $FixAnimation

export var fixed = false

signal started_fixing


func _on_FixArea_body_entered(body):
	print(body, " entered")
	if body is Player:
		_player = body
		body.grapnel_enabled = false
		_ready_to_fix = true


func _on_FixArea_body_exited(body):
	if body is Player:
		body.grapnel_enabled = true
		_ready_to_fix = false


func _process(_delta):
	if _ready_to_fix and Input.is_action_just_pressed("interact"):
		_player.control_enabled = false
		_player.go_to($FixingPosition.global_position)
		_player.connect("reached_target", self, "start_fix")


func start_fix():
	_player.disconnect("reached_target", self, "start_fix")
	_player.visible = false
	_player_puppet.global_position = _player.global_position
	_player_puppet.visible = true
	
	emit_signal("started_fixing")
	_fix_animation.play("fix")
	
