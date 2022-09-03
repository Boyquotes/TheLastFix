extends PlayableLevel

onready var _cutscene_player = $CutscenePlayer


func _ready():
	_cutscene_player.play("intro")


func _on_DeathArea_body_entered(body):
	if body is Player:
		body.position = _active_screen.spawnpoint + _active_screen.position
		_grapnel.retract()
