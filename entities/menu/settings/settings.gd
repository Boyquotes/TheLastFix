extends Submenu

var _made_changes = false
@onready var _settings = Game.Settings
@onready var _volume_value = $Volume/Value


func _ready():
	_volume_value.text = str(_settings.volume)


func exit():
	if _made_changes:
		_settings.save()
		_made_changes = false


func _update_settings():
	_volume_value.text = str(_settings.volume)


func _process(_delta):
	var volume = _settings.volume

	var changed = false
	if current_option == "Volume":
		if Input.is_action_just_pressed("move_left") and volume > 0:
			_settings.volume -= 1
			changed = true

		if Input.is_action_just_pressed("move_right") and volume < _settings.MAX_VOLUME:
			_settings.volume += 1
			changed = true

		if changed:
			_made_changes = true
			_update_settings()


func choose():
	match current_option:
		"Volume":
			return false

		"Back":
			emit_signal("back")

	return true
