extends Node2D

class_name Fixable

var _ready_to_fix = false
var _player: Player

onready var _player_puppet = $PlayerPuppet
onready var _fix_animation = $FixAnimation
onready var _prompt_hover = $PromptHoverAnimation

export var fixed = false
export var return_to_player_after = true
export var fixable_index: int

signal started_fixing
signal finished_fixing


func _ready():
	_prompt_hover.play("hover")


func _on_FixArea_body_entered(body):
	if body is Player and not fixed:
		_player = body
		body.grapnel_enabled = false
		_ready_to_fix = true
		_fix_animation.play("prompt_open")


func _on_FixArea_body_exited(body):
	if body is Player and not fixed:
		body.grapnel_enabled = true
		_ready_to_fix = false
		_fix_animation.play("prompt_close")


func _process(_delta):
	if _ready_to_fix and Input.is_action_just_pressed("interact"):
		_ready_to_fix = false
		_player.grapnel_enabled = true
		_player.go_to($FixingPosition.global_position, $FixingPosition.position.x > 0)
		var error = _player.connect("reached_target", self, "start_fix")
		if error != OK:
			print("Error connecting reached_target: ", error)
		_fix_animation.play("prompt_use")


func start_fix():
	_prompt_hover.stop()
	_player.disconnect("reached_target", self, "start_fix")
	_player.visible = false
	_player_puppet.global_position = _player.global_position
	_player_puppet.visible = true
	
	emit_signal("started_fixing")
	_fix_animation.queue("fix")


func _on_FixAnimation_animation_finished(anim_name):
	if anim_name != "fix":
		return

	fixed = true
	_ready_to_fix = false
	var popup = Game.load_gui(preload("res://scenes/page_popup/page_popup.tscn"))
	popup.set_crossed(fixable_index - 1)
	popup.connect("close_page", self, "post_fix")


func post_fix():
	emit_signal("finished_fixing")
	if return_to_player_after:
		_player_puppet.visible = false
		_player.visible = true
		_player.control_enabled = true
