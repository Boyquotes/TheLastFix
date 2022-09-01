extends Node2D

class_name Level

var game: Main


func set_game(main):
	game = main


func reload():
	game.reload_current_level()
