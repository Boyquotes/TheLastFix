extends Fixable


onready var _sprite = $Sprite
onready var _light = $Light
onready var _hum_sound = $HumSound
onready var _animation_player = $AnimationPlayer


func _ready():
	_animation_player.play("flicker")


func _on_Sprite_frame_changed():
	_hum_sound.stream_paused = _sprite.frame == 0
	_light.enabled = _sprite.frame == 1
	_sprite.light_mask = 1 if _sprite.frame == 0 else 0


func on_finished_fixing():
	_hum_sound.pause_mode = PAUSE_MODE_INHERIT
