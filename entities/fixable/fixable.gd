extends Node2D

class_name Fixable

var _ready_to_fix = false
var _player: Player

@onready var _player_puppet = $PlayerPuppet
@onready var _fix_animator = $FixAnimator
@onready var _prompt = $Prompt

@export var enabled = true
@export var fixed = false
@export var zoom_before_animation = true
@export var zoom_offset = Vector2.ZERO
@export var return_to_player_after = true
@export var fixable_index: int

signal started_fixing
signal finished_fixing


func _process(_delta):
	_prompt.monitoring = enabled


func _on_Prompt_used():
	_player = Game.get_player()
	_player.go_to($FixingPosition.global_position, $FixingPosition.position.x > 0)
	var error = _player.connect("reached_target", start_fix, CONNECT_ONE_SHOT)
	assert(error == 0) #,"Error connecting reached_target: " + str(error))


func start_fix():
	emit_signal("started_fixing")

	if zoom_before_animation:
		Game.zoom_in(1, 0.5, (_player_puppet.global_position + global_position) / 2 + zoom_offset)
		var error = Game.connect("zoom_finished", on_zoom_finished)
		assert(error == 0) #,"Error connecting zoom_finished: " + str(error))
	else:
		_player.visible = false
		_player_puppet.global_position = _player.global_position
		_player_puppet.visible = true
		_fix_animator.play("fix")


func on_zoom_finished():
	if fixed:
		Game.disconnect("zoom_finished", on_zoom_finished)
		if return_to_player_after:
			_player.control_enabled = true
	else:
		_player.visible = false
		_player_puppet.global_position = _player.global_position
		_player_puppet.visible = true
		_fix_animator.play("fix")


func _on_FixAnimation_animation_finished(anim_name):
	if anim_name != "fix":
		return

	fixed = true
	_ready_to_fix = false
	var popup = Game.load_gui(preload("res://scenes/page_popup/page_popup.tscn"))
	popup.set_crossed(fixable_index - 1)
	popup.connect("close_page", post_fix)


func post_fix():
	emit_signal("finished_fixing")
	if return_to_player_after:
		_player_puppet.visible = false
		_player.visible = true
		if not zoom_before_animation:
			_player.control_enabled = true

	if zoom_before_animation:
		Game.zoom_out(0.6)
