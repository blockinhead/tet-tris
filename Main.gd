extends Node2D

var brick: PackedScene = preload("res://Objects/brick.tscn")

const glass_height = 18
const glass_width = 10
const spawn_point = Vector2(glass_width / 2, 3)

const cell_step = 40
const cell_size = Vector2(cell_step / 2, cell_step / 2)
const cell_size_bordered = cell_size * 0.9
var current_figure: Array[Vector2]
var glass: Array
var update_timer = Timer.new()
var max_wait_time = 0.6
var min_wait_time = 0.2
var wait_time_step = 0.01
var min_fast_time = 3
var current_fast_time = min_fast_time
var general_timer = Timer.new()

var score = 0: set = update_score

var moving_down = false
var is_game_over = true


func  update_score(val: int):
	score = val
	$CanvasLayer/VBoxContainer/Score.text = 'score: %04d' % val


func game_to_screen(pos: Vector2) -> Vector2:
	var offset = Vector2(100, 100)
	return (pos * cell_size) + offset
	

# Called when the node enters the scene tree for the first time.
func _ready():
	_draw_walls()
	
	update_timer.connect('timeout', update_state)
	update_timer.wait_time = max_wait_time
	add_child(update_timer)
	
	general_timer.connect('timeout', update_update_timer)
	general_timer.wait_time = 1
	add_child(general_timer)
	
	$GameOver.NewGamePressed.connect(new_game)
	
	new_game()
	
	preview_figure()
	
func update_update_timer():
	update_timer.wait_time = max(update_timer.wait_time - wait_time_step, min_wait_time)
	if update_timer.wait_time <= min_wait_time:
		current_fast_time -= 1
		
	if current_fast_time < 0:
		update_timer.wait_time = max_wait_time
		current_fast_time = min_fast_time
		
	$CanvasLayer/VBoxContainer/Speed.text = 'speed: %03.2f' % update_timer.wait_time
		
	
	
func new_game():
	$GameOver.hide()
	# game_over()
	# return
	current_figure.clear()
	_init_glass()
	_spawn_figure()
	update_timer.start()
	general_timer.start()
	is_game_over = false
	
	
func update_state():
	var next_state = shift(Vector2.DOWN)
	if not check(next_state):
		moving_down = false
		remove_full()
		_spawn_figure()
	else:
		redraw_figure(next_state)
	
	
func _init_glass():
	for i in range(len(glass)):
		for j in range(len(glass[i])):
			var b = brick_from_glass(Vector2(j, i))
			if b != null:
				b.queue_free()
				
	glass.clear()
	for i in range(glass_height):
		var row = Array()
		row.resize(glass_width)
		row.fill(null)
		glass.append(row)

func brick_from_glass(pos: Vector2):
	# if glass[pos.y][pos.x] == null:
	# 	return false
	return glass[pos.y][pos.x]


		
func _draw_brick(pos: Vector2, color = Color.ANTIQUE_WHITE):
	assert(glass[pos.y][pos.x] == null, 'attempting to draw on nonvacant position')
	var b = brick.instantiate();
	add_child(b)
	b.modulate = color
	b.position = game_to_screen(pos)
	b.scale = cell_size_bordered
	
	if pos.y >= 0:
		glass[pos.y][pos.x] = b
		

func move_bricks(old_poses: Array, new_poses: Array):
	var l = len(old_poses)
	assert(l == len(new_poses), 'amount of source poses differs from amount of target poses')
	var tmp = Array()
	tmp.resize(l)
	for i in range(l):
		tmp[i] = glass[old_poses[i].y][old_poses[i].x]
		glass[old_poses[i].y][old_poses[i].x] = null

	for i in range(l):
		assert(brick_from_glass(new_poses[i]) == null, 'moving brick to nonvacant position')
		tmp[i].position = game_to_screen(new_poses[i])
		glass[new_poses[i].y][new_poses[i].x] = tmp[i]

func _draw_walls(height=glass_height, width=glass_width):
	var color = Color.ANTIQUE_WHITE
	var draw_brick = func (pos):
		var b = brick.instantiate();
		add_child(b)
		b.modulate = color
		b.position = game_to_screen(pos)
		b.scale = cell_size_bordered

	for i in range(height + 1):
		draw_brick.call(Vector2(-1, i))
	for i in range(height + 1):
		draw_brick.call(Vector2(width, i))
	for i in range(width + 1):
		draw_brick.call(Vector2(i, height))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_game_over:
		return
		
	if Input.is_action_just_pressed('ui_up'):
		var next_state = _rotate_figure()
		if check(next_state):
			$Sounds.turn()
			redraw_figure(next_state)
			
	elif Input.is_action_just_pressed('ui_down'):
		moving_down = true
	elif Input.is_action_pressed('ui_down') and moving_down:
		$Sounds.drop()
		update_state()
	elif Input.is_action_just_released("ui_down"):
		moving_down = false
	
	elif Input.is_action_just_pressed('ui_left'):
		var next_state = shift(Vector2.LEFT)
		if check(next_state):
			$Sounds.move()
			redraw_figure(next_state)
	elif Input.is_action_just_pressed('ui_right'):
		var next_state = shift(Vector2.RIGHT)
		if check(next_state):
			$Sounds.move()
			redraw_figure(next_state)
		

func _get_figure():
	var figures = [
		[[Vector2(-1, 0),  # L
		  Vector2(0, 0),
		  Vector2(1, 0),
		  Vector2(1, -1),
		], Color.CORAL],
			
		[[Vector2(1, 0),  # J
		  Vector2(0, 0),
		  Vector2(-1, 0),
		  Vector2(-1, -1),
		], Color.BLUE],

		[[Vector2(0, 0),  # O
		  Vector2(1, 0),
		  Vector2(1, 1),
		  Vector2(0, 1),
		], Color.YELLOW],
			
		[[Vector2(-1, 0),  # I
		  Vector2(0, 0),
		  Vector2(1, 0),
		  Vector2(2, 0),
		], Color.SKY_BLUE],
		
		[[Vector2(-1, 0),  # S
		  Vector2(0, 0),
		  Vector2(0, 1),
		  Vector2(1, 1),
		], Color.WEB_GREEN],

		[[Vector2(-1, 0),  # T
		  Vector2(0, 0),
		  Vector2(1, 0),
		  Vector2(0, -1),
		], Color.PURPLE],

		[[Vector2(-1, 0),  # Z
		  Vector2(0, 0),
		  Vector2(0, -1),
		  Vector2(1, -1),
		], Color.FIREBRICK]
	]
	
	return figures.pick_random()
	
func _spawn_figure():
	current_figure = []
	var _f = _get_figure()
	var next_state: Array[Vector2] = []
	for p in _f[0]:
		next_state.append(p + spawn_point)
	if not check(next_state):
		game_over()
		return
		
	current_figure = next_state
	for p in current_figure:
		_draw_brick(p, _f[1])
		
func redraw_figure(new_coords: Array[Vector2]):
	move_bricks(current_figure, new_coords)
	current_figure = new_coords
	
		
func _rotate_figure():
	var p = current_figure[1]
	var x = 0
	var y = 0
	var _rotated: Array[Vector2]
	_rotated.resize(4)
	_rotated.fill(Vector2(0, 0))
	
	for i in [0, 1, 2, 3]:
		x = current_figure[i].y - p.y
		y = current_figure[i].x - p.x
		_rotated[i].x = p.x - x
		_rotated[i].y = p.y + y
		
	return _rotated
	
func shift(direction):
	if len(current_figure) == 0:
		game_over()
		return
		
	var _updated: Array[Vector2]
	_updated.resize(4)
	_updated.fill(Vector2(0, 0))
	
	for i in range(4):
		_updated[i] = current_figure[i] + direction
		
	return _updated
	
func check(next_state):
	for i in range(4):
		if next_state[i] in current_figure:
			continue
		if next_state[i].x < 0 or next_state[i].x >= glass_width:
			return false
		if next_state[i].y >= glass_height:
			return false
		if next_state[i].y > 0 and next_state[i].x >= 0 and next_state[i].x < glass_width and brick_from_glass(next_state[i]):
			return false
	return true
	

func remove_full_row(row_index):
	for i in range(0, glass_width):
		glass[row_index][i].queue_free()
		glass[row_index][i] = null
		
func move_row_down(row_index, amount):
	if amount == 0:
		return
		
	var src_poses = []
	var dst_poses = []
	for i in range(0, glass_width):
		var s = Vector2(i, row_index)
		if brick_from_glass(s):
			src_poses.append(s)
			dst_poses.append(s + Vector2.DOWN * amount)
	if src_poses:
		move_bricks(src_poses, dst_poses)
		
func is_row_full(row_index) -> bool:
	for i in range(0, glass_width):
		if not brick_from_glass(Vector2(i, row_index)):
			return false
	return true
		
func remove_full():
	
	var num_removed = 0
	var current_row = glass_height - 1
	while current_row >= 0:
		if is_row_full(current_row):
			# print('row %d is full' % current_row)
			$Sounds.remove_line()
			num_removed += 1
			remove_full_row(current_row)
			for i in range(current_row - 1, 0, -1):
				move_row_down(i, 1)
		else:
			current_row -= 1
			
	score += num_removed
		

func game_over():
	is_game_over = true
	update_timer.stop()
	general_timer.stop()
	$GameOver.show()

func preview_figure():
	var b = brick.instantiate();
	$CanvasLayer/VBoxContainer/NextFigure.add_child(b)
	b.modulate = Color.ANTIQUE_WHITE
	b.position = game_to_screen(Vector2(0, 0))
	b.scale = cell_size_bordered
	
