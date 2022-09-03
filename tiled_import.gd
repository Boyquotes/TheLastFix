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

	screen.get_node("ScreenArea/CollisionArea").shape.extents = size / 2
	return screen
