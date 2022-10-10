extends Light2D


func _ready():
	Game.connect("player_light_changed", self, "_on_change")


func _on_change(_energy: float):
	energy = _energy
