extends AnimationPlayer


class_name Animator

# Extension of the AnimationPlayer node to enable additional global functionality,
# including fading of the screen, zooming, and playing dialogue.

var _paused_for_dialogue = false
var _dialogue: Dialogue

func _ready():
	_dialogue = Game.get_dialogue()


func play_dialogue_sequence(id: String):
	_dialogue.play_sequence(id)
	playback_active = false
	_paused_for_dialogue = true
	var error = _dialogue.connect("paused", self, "on_dialogue_paused")
	if error != 0:
		print("Error connecting dialogue_paused: ", error)


func continue_dialogue():
	_dialogue.resume()
	playback_active = false
	_paused_for_dialogue = true
	var error = _dialogue.connect("paused", self, "on_dialogue_paused")
	if error != 0:
		print("Error connecting dialogue_paused: ", error)


func on_dialogue_paused():
	if _paused_for_dialogue:
		_dialogue.disconnect("paused", self, "on_dialogue_paused")
		playback_active = true
		_paused_for_dialogue = false


func fade_in(time: float):
	Game.fade_in(time)


func fade_out(time: float):
	Game.fade_out(time)


func zoom_in(time: float, level: float, center: Vector2 = Vector2(-1, -1)):
	Game.zoom_in(time, level, center)


func zoom_out(time: float):
	Game.zoom_out(time)


func set_zoom(level: float, center: Vector2 = Vector2(-1, -1)):
	Game.set_zoom(level, center)


func mark_end_cutscene():
	Game._current_level.end_cutscenes = true


func set_player_movement(enabled: bool):
	Game.get_player().control_enabled = enabled
	if not enabled:
		Game.get_player()._grapnel.retract()
