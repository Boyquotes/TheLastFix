extends Control

class_name GUIScene

@export var allow_fade = true


func close():
	Game.unload_gui(self)
