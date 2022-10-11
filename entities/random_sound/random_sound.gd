extends AudioStreamPlayer

class_name RandomSound


export var path_start = ""
export var path_end = ".mp3"
export var count = 0

var streams = []


func _ready():
	for i in count:
		streams.append(load(path_start + str(1 + i) + path_end))


func play(from_position: float = 0.0):
	stream = streams[randi() % count]
	return .play(from_position)
