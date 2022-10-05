extends Node2D

class_name Level

export var fade_level = 1.0 setget _set_fade_level
export var zoom_level = 1.0 setget _set_zoom_level
export var zoom_center = Vector2.ZERO setget _set_zoom_center

onready var camera: Camera2D = $Camera
onready var _cutscene_player = $CutscenePlayer

var _paused_for_dialogue = false


func play_dialogue_sequence(id: String):
	Game.play_dialogue_sequence(id)
	if _cutscene_player.playback_active:
		_cutscene_player.playback_active = false
		_paused_for_dialogue = true
		var error = Game.connect("dialogue_ended", self, "continue_after_dialogue")
		if error != 0:
			print("Error connecting dialogue_ended: ", error)


func continue_after_dialogue():
	if _paused_for_dialogue:
		Game.disconnect("dialogue_ended", self, "continue_after_dialogue")
		_cutscene_player.playback_active = true
		_paused_for_dialogue = false


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
		zoom_center = center - camera.get_camera_position()
		Game.get_camera().offset = (1 - zoom_level) * zoom_center
