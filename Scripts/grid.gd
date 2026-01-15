extends Node2D
#wonder if i can fit the whole game in one script and scene

var width : int
var height : int
@export var alive_tile := 1
@export var dead_tile := 0
@export var player_tile:= 2
@export var goal_tile := 3
@export var start_tile:= 4

@onready var life_layer : TileMapLayer = $LifeLayer
@onready var ui := $RoundUi
@onready var round_label := $RoundUi/ColorRect/Label


var player_position: Vector2i
var is_player_alive:= true
var roundnum : int = 0
var going_from_left_to_right: bool = false
var showing_the_round_num_screen: bool = false



var grid: Array = []

func _ready():
	randomize()
	
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /16
	@warning_ignore("integer_division")
	height = viewport_size.y / 16
	advance()
	initialize_grid()
	spawn_player(4)
	draw_start_and_goal()
	draw_said_grid()
	draw_player()

#player 
func spawn_player(y: int):
	player_position = Vector2i(get_start_x(), y)

func move_player(direction: Vector2i):
	if not is_player_alive:
		return
	if player_position.x == get_goal_x():
		advance()
		return
	
	var new_pos := player_position + direction
	
	if new_pos.x < 0 or new_pos.x >= width:
		return
	if new_pos.y < 0 or new_pos.y >= height:
		return
	
	player_position = new_pos
	life()
	
	if grid[player_position.y][player_position.x]:
		is_player_alive = false
		return
	
	draw_player()

# drawing the sqaures
func draw_player():
	life_layer.set_cell(player_position, player_tile, Vector2i.ZERO)

func draw_start_and_goal():
	var starting_x := get_start_x()
	var goal_x := get_goal_x()
	
	for y in range(height):
		life_layer.set_cell(Vector2i(starting_x, y), start_tile, Vector2i.ZERO)
		life_layer.set_cell(Vector2i(goal_x, y), goal_tile, Vector2i.ZERO)

func draw_said_grid():
	life_layer.clear()
	
	for y in range(height):
		for x in range(width):
			var title_id : int = alive_tile if grid[y][x] else dead_tile
			life_layer.set_cell(Vector2i(x,y), title_id, Vector2i.ZERO)

func advance():
	showing_the_round_num_screen = true
	roundnum += 1
	going_from_left_to_right= !going_from_left_to_right
	
	show_switch_screen()
	await get_tree().create_timer(1.5).timeout
	
	ui.visible = false
	reset_grid()
	showing_the_round_num_screen = false

func show_switch_screen():
	round_label.text = "round %d" % roundnum
	ui.visible = true

func reset_grid():
	initialize_grid()
	draw_said_grid()
	draw_start_and_goal()
	
	player_position = Vector2i(get_start_x(), player_position.y)
	draw_player()

func initialize_grid():
	grid.clear()
	
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(randf() < 0.2)
		
		grid.append(row)

func life():
	var new_grid: Array = []
	
	for y in range(height):
		var row: Array[bool] = []
		for x in range(width):
			if cant_grow_cell_checker(x):
				row.append(false)
				continue
				
			var next_cell := count_next_cells(x,y)
			var alive : bool = grid[y][x]
			
			
			if alive:
				row.append(next_cell == 2 or next_cell == 3)
			else:
				row.append(next_cell == 3)
		new_grid.append(row)
		
	
	grid = new_grid
	draw_said_grid()
	draw_start_and_goal()

func count_next_cells(x: int, y:int) -> int:
	# The 4 Rules of Conways Game of Life
	#Any live cell with fewer than two live neighbors dies.
	#Survival: 
	#Any live cell with two or three live neighbors lives on to the next generation.
	#Overpopulation: 
	#Any live cell with more than three live neighbors dies.
	#Reproduction: 
	#Any dead cell with exactly three live neighbors becomes a live cell. 

	var count := 0
	
	for dy: int in [-1, 0, 1]:
		for dx: int in [-1,0,1]:
			if dx == 0 and dy == 0:
				continue
				
			var nx: int = (x + dx + width) % width
			var ny : int= (y + dy + height) % height
				
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				if grid[ny][nx]:
					count +=1
						
	return count
func get_start_x() -> int:
	return 0 if going_from_left_to_right else width - 1
func get_goal_x() -> int:
	return width - 1 if going_from_left_to_right else 0
func cant_grow_cell_checker(x : int) -> bool:
	return x == get_goal_x() or x == get_start_x()

func _input(event: InputEvent) -> void:
	if showing_the_round_num_screen:
		return
	
	if event.is_action_pressed("ui_accept"):
		life()
		
	if event.is_action_pressed("ui_up"):
		move_player(Vector2i(0,-1))
	elif event.is_action_pressed("ui_down"):
		move_player(Vector2i(0,1))
	elif event.is_action_pressed("ui_left"):
		move_player(Vector2i(-1,0))
	elif event.is_action_pressed("ui_right"):
		move_player(Vector2i(1,0))
