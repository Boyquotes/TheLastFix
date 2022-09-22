extends Level

class_name PlayableLevel

onready var _player = $Player
onready var _grapnel = $Grapnel

export var start_at_screen = ""

var _active_screen: Screen

var followed_node = null


func _ready():
	followed_node = _player
	_player.set_grapnel(_grapnel)
	
	for node in get_children():
		if node is Screen:
			node.set_level(self)

	if not start_at_screen.empty():
		set_active_screen(get_node(start_at_screen))
		_player.stand_on(_active_screen.global_position + (
			_active_screen.spawnpoints[0] if not _active_screen.spawnpoints.empty() else Vector2.ZERO
		))
		_player.control_enabled = true
		_player.visible = true
		_player.play_idle()


func _process(_delta):
	if followed_node != null:
		camera.position = followed_node.position


func set_active_screen(screen: Screen):
	if _active_screen != null:
		_active_screen.active = false
		_active_screen.disable_blockers()

	_active_screen = screen
	screen.active = true
	_grapnel.retract()

	var limit = screen.get_extents()
	print("Switched to screen ", screen.name)

	camera.limit_left = limit.position.x
	camera.limit_top = limit.position.y
	camera.limit_right = limit.end.x
	camera.limit_bottom = limit.end.y
	
	# Find spawnpoint closest to player
	var min_dist = INF
	var closest_spawn = null
	for spawn in screen.spawnpoints:
		var dist = (screen.global_position + spawn).distance_to(_player.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_spawn = screen.global_position + spawn

	if closest_spawn != null:
		_player.spawnpoint = closest_spawn


func fall_from_screen():
	_player.die()
