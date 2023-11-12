extends Node

var brick: PackedScene = preload("res://Objects/brick.tscn")

const cell_step = 40
const cell_size = Vector2(cell_step / 2, cell_step / 2)
const cell_size_bordered = cell_size * 0.9

func game_to_screen(pos: Vector2) -> Vector2:
	# var offset = Vector2(100, 100)
	return (pos * cell_size)  # + offset
	
func draw_brick(pos: Vector2, color = Color.ANTIQUE_WHITE, offset = Vector2(0, 0)):
	var b = brick.instantiate();
	# add_child(b)
	b.modulate = color
	b.position = game_to_screen(pos) + offset
	b.scale = cell_size_bordered
	return b
	

