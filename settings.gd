extends Node

const FILE_PATH = "user://settings.json"

const MAX_VOLUME = 10
var volume: int : set = _set_volume


func _ready():
	var data = {}
	if FileAccess.file_exists(FILE_PATH):
		var _file = FileAccess.open(FILE_PATH, FileAccess.READ)
		
		var json_conv = JSON.new()
		json_conv.parse(_file.get_as_text())
		data = json_conv.get_data()
		if data == null:
			data = {}

	_set_volume(data.get("volume", MAX_VOLUME))


func _set_volume(value: int):
	volume = value
	AudioServer.set_bus_volume_db(0, log(float(volume) / MAX_VOLUME) * 15)


func save():
	var _file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	_file.store_string(JSON.stringify({
		"volume": volume
	}))
