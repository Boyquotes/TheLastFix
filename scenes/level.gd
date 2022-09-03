extends Node2D

class_name Level

var game: Main
export var fade_level = 1.0 setget _set_fade_level
export var zoom_level = 1.0 setget _set_zoom_level
export var zoom_center = Vector2.ZERO setget _set_zoom_center

onready var _camera: Camera2D = $Camera


func set_game(main):
	game = main
	_set_zoom_level(zoom_level)


func reload():
	game.reload_current_level()


func _set_fade_level(level: float):
	fade_level = level

	if game != null:
		var view = game.get_view()
		view.modulate = Color(level, level, level)


func _set_zoom_level(level: float):
	zoom_level = level
	
	if game != null:
		var camera = game.get_camera()
		camera.zoom = Vector2(level, level)
		camera.offset = (1 - level) * zoom_center


func _set_zoom_center(center: Vector2):
	if game != null and _camera != null:
		zoom_center = center - _camera.position
		game.get_camera().offset = (1 - zoom_level) * zoom_center
