extends PointLight2D


func _ready():
	var error = Game.connect("player_light_changed", _on_change)
	assert(error == 0) #,"Error connecting player_light_changed: " + str(error))


func _on_change(player_energy: float, _grapnel_energy: float):
	energy = player_energy
