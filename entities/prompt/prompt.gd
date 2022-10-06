extends Node2D

signal used


onready var _prompt_animation = $PromptAnimation

var _ready_to_use = false
var _player: Player
var _used = false

func _ready():
	$HoverAnimation.play("hover")


func _on_body_entered(body):
	if body is Player and not _used:
		_player = body
		body.grapnel_enabled = false
		_prompt_animation.play("prompt_open")
		_ready_to_use = true


func _on_body_exited(body):
	if body is Player:
		body.grapnel_enabled = true
		_prompt_animation.play("prompt_close")
		_ready_to_use = false


func _process(_delta):
	if _ready_to_use and Input.is_action_just_pressed("interact"):
		_ready_to_use = false
		_player.grapnel_enabled = true
		_prompt_animation.play("prompt_use")
		_used = true
		emit_signal("used")
