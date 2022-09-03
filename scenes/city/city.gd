extends PlayableLevel

onready var _cutscene_player = $CutscenePlayer


func _ready():
	_cutscene_player.play("intro")
