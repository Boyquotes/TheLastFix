extends Node

const Screen = preload("res://scenes/screen/screen.tscn")


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
			for object in node.get_children():
				match object.get_meta("type"):
					"spawn":
						screen.spawnpoint = object.position - size / 2

	screen.get_node("ScreenArea/CollisionArea").shape.extents = size / 2
	return screen


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
