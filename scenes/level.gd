extends Node2D

class_name Level

@onready var camera: Camera2D = $Camera

var followed_node: Node2D : set = _set_followed_node
var camera_offset = Vector2.ZERO


func get_save_data():
	return {}


func _process(_delta):
	if followed_node != null:
		camera.position = followed_node.global_position + camera_offset


func _set_followed_node(node: Node2D):
	followed_node = node
	if node != null:
		camera.position = node.global_position
