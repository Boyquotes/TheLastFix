extends Node

const Screen = preload("res://scenes/screen/screen.tscn")
const CameraArea = preload("res://scenes/screen/camera_area.tscn")
const UtilityPole = preload("res://entities/utility_pole/utility_pole.tscn")


func post_import(scene: Node2D):
	var screen = Screen.instance()
	var size = Vector2.ZERO

	for node in scene.get_children():
		if node is TileMap:
			for tile in node.get_used_cells():
				if tile.x > size.x:
					size.x = tile.x
				if tile.y > size.y:
					size.y = tile.y
			size = (Vector2(1, 1) + size) * 8
			node.position -= size / 2
			scene.remove_child(node)
			screen.add_child(node)
			node.set_owner(screen)
			add_occlusion(node.tile_set)
			
		elif node is Node2D:  # Object layer
			var object_layer = node
			for object in object_layer.get_children():
				match object.get_meta("type"):
					"spawn":
						screen.spawnpoint = object.position - size / 2
					"camera_area":
						var limits_body: StaticBody2D = object_layer.get_node(object.get_meta("limits"))
						var collision: CollisionPolygon2D = object.get_child(0)
						var camera_area = CameraArea.instance()

						var camera_area_size = limits_body.get_child(0).shape.extents
						camera_area.limits = Rect2(limits_body.position - size / 2, camera_area_size * 2)
						collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
						object.remove_child(collision)

						camera_area.add_child(collision)
						screen.add_child(camera_area)
						camera_area.position = object.position - size / 2

						camera_area.set_owner(screen)
						collision.set_owner(screen)
					"upole":
						var pole = UtilityPole.instance()
						pole.position = object.position - size / 2
						
						pole.right_end = connect_pole(object, "right_connect", object_layer)
						pole.left_end = connect_pole(object, "left_connect", object_layer)
						print(pole.left_end)
						
						screen.add_child(pole)
						pole.set_owner(screen)
					_:
						print("UNKNOWN TILED OBJECT: ", object)

	screen.get_node("ScreenArea/CollisionArea").shape.extents = size / 2
	return screen


func connect_pole(object: Node2D, tag: String, object_layer: Node2D):
	if not object.has_meta(tag):
		return Vector2.ZERO

	var end = object_layer.get_node(object.get_meta(tag))
	if end is Sprite:  # Connects to pole
		return end.position - object.position + Vector2(35 if tag == "left_connect" else 1, -84)
	return end.position - object.position


func add_occlusion(tileset: TileSet):
	for id in tileset.get_tiles_ids():
		var occluder = OccluderPolygon2D.new()
		var shape = tileset.tile_get_shape(id, 0)
		if shape is RectangleShape2D:
			var extents = shape.extents * 2
			occluder.polygon = [
				Vector2.ZERO,
				Vector2(extents.x, 0),
				extents,
				Vector2(0, extents.y)
			]
		else:
			continue

		tileset.tile_set_light_occluder(id, occluder)
