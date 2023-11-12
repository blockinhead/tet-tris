extends Node2D


var figure: Array[Vector2]
var blocks = Array()
var spawn_point = Vector2(2, 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func draw_figure(positions, color):
	if len(blocks):
		for b in blocks:
			b.queue_free()
			
	blocks = Array()			
	for p in positions:
		var b = Global.draw_brick(p + spawn_point, color)
		add_child(b)
		blocks.append(b)
		
