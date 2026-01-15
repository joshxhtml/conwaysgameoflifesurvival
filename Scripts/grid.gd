extends Node2D

var width : int
var height : int
@export var alive_tile := 1
@export var dead_tile := 0

@onready var life_layer : TileMapLayer = $LifeLayer

#if grid[y][x] is true then itll be alive, and if its false itll be dead, for future reference
var grid: Array = []

func _ready():
	randomize()
	
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /16
	@warning_ignore("integer_division")
	height = viewport_size.y / 16
	
	initialize_grid()
	draw_said_grid()

func initialize_grid():
	grid.clear()
	
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(randf() < 0.2)
		
		grid.append(row)

func draw_said_grid():
	life_layer.clear()
	
	for y in range(height):
		for x in range(width):
			var title_id : int = alive_tile if grid[y][x] else dead_tile
			life_layer.set_cell(Vector2i(x,y), title_id, Vector2i.ZERO)

func life():
	var new_grid: Array = []
	
	for y in range(height):
		var row: Array[bool] = []
		for x in range(width):
			var next_cell := count_next_cells(x,y)
			var alive : bool = grid[y][x]
			if alive:
				row.append(next_cell == 2 or next_cell == 3)
			else:
				row.append(next_cell == 3)
		new_grid.append(row)
		
	
	grid = new_grid
	draw_said_grid()

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
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		life()
