extends StaticBody2D

onready var _entrance = $Entrance
onready var _occluder = $Occluder
onready var _stairs = $Stairs
onready var _ceiling = $Ceiling
export var enabled = true setget _set_enabled


func _ready():
	flush_enabled()


func _on_TopOfStairs_body_entered(body):
	if enabled and body is Player:
		_entrance.set_deferred("disabled", not _entrance.disabled)


func _set_enabled(value: bool):
	enabled = value
	if _occluder != null and _stairs != null and _ceiling != null:
		flush_enabled()


func flush_enabled():
	_occluder.light_mask = 1 if enabled else 0
	_stairs.set_deferred("disabled", not enabled)
	_ceiling.set_deferred("disabled", not enabled)
