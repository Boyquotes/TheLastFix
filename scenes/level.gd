extends Node2D

class_name Level

export var fade_level = 1.0 setget _set_fade_level
export var zoom_level = 1.0 setget _set_zoom_level
export var zoom_center = Vector2.ZERO setget _set_zoom_center

onready var camera: Camera2D = $Camera


func play_dialogue_sequence(id: String):
	Game.play_dialogue_sequence(id)


func _set_fade_level(level: float):
	fade_level = level

	var view = Game.get_view()
	if view != null:
		view.modulate = Color(level, level, level)


func _set_zoom_level(level: float):
	zoom_level = level
	
	var game_camera = Game.get_camera()
	if game_camera != null:
		game_camera.zoom = Vector2(level, level)
		game_camera.offset = (1 - level) * zoom_center


func _set_zoom_center(center: Vector2):
	if camera != null:
		zoom_center = center - camera.position
		Game.get_camera().offset = (1 - zoom_level) * zoom_center
