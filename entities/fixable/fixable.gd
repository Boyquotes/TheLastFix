extends Node2D

class_name Fixable

var _ready_to_fix = false
var _player: Player

onready var _player_puppet = $PlayerPuppet
onready var _fix_animation = $FixAnimation

export var fixed = false
export var return_to_player_after = true

signal started_fixing
signal finished_fixing


func _on_FixArea_body_entered(body):
	if body is Player and not fixed:
		_player = body
		body.grapnel_enabled = false
		_ready_to_fix = true


func _on_FixArea_body_exited(body):
	if body is Player and not fixed:
		body.grapnel_enabled = true
		_ready_to_fix = false


func _process(_delta):
	if _ready_to_fix and Input.is_action_just_pressed("interact"):
		_player.control_enabled = false
		_player.grapnel_enabled = true
		_player.go_to($FixingPosition.global_position)
		_player.connect("reached_target", self, "start_fix")


func start_fix():
	_player.disconnect("reached_target", self, "start_fix")
	_player.visible = false
	_player_puppet.global_position = _player.global_position
	_player_puppet.visible = true
	
	emit_signal("started_fixing")
	_fix_animation.play("fix")


func _on_FixAnimation_animation_finished(_anim_name):
	fixed = true
	_ready_to_fix = false
	var popup = Game.load_gui(preload("res://scenes/page_popup/page_popup.tscn"))
	popup.connect("close_page", self, "post_fix")


func post_fix():
	emit_signal("finished_fixing")
	if return_to_player_after:
		_player_puppet.visible = false
		_player.visible = true
		_player.control_enabled = true
