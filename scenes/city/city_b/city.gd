extends PlayableLevel


func _ready():
	Game.set_zoom(0.5625, Vector2(0, -2))
	Game.fade_in(0.5)
	_player.scale.x = -1
	_player._flipped = true
	_player.play_idle()
