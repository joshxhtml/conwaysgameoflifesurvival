extends Node2D

@export var cell_size := 16
@export var alive_tile := 1
@export var dead_tile := 0
@onready var life_layer : TileMapLayer = $LifeLayer

var width : int 
var height : int


var grid := []
var running := false
var time := 0.25

func _ready() -> void:
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /cell_size
	@warning_ignore("integer_division")
	height = (viewport_size.y / 16) + 3
	intialize()
	draw_gird()

func _process(delta: float) -> void:
	if running: 
		time -= delta
		if time <= 0:
			life()
			time = $UI/ColorRect/SpeedSlider.value

#forth times a charm 😭😭
func intialize():
	grid.clear()
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(false)
		grid.append(row)

func draw_gird():
	life_layer.clear()
	for y in range(height):
		for x in range(width):
			life_layer.set_cell(
				Vector2i(x, y),
				alive_tile if grid[y][x] else dead_tile,
				Vector2i.ZERO
			)
			
func life():
	var new_grid := []
	
	for y in range(height):
		var row := []
		for x in range(width):
			var n :int= count_neighbors(x, y)
			var alive :bool= grid[y][x]
			var next := false
			
			if alive and (n == 2 or n == 3):
				next = true
			elif not alive and n == 3:
				next = true
				
			row.append(next)
		new_grid.append(row)
		
	grid = new_grid
	draw_gird()
	

func count_neighbors(x, y):
	var count := 0
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx :int= x + dx
			var ny :int= y + dy
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				if grid[ny][nx]:
					count += 1
	return count

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < width and p.y >= 0 and p.y < height


func _on_play_pressed() -> void:
	running = !running



func _on_step_pressed() -> void:
	if not running:
		life()


func _on_clear_pressed() -> void:
	intialize()
	draw_gird() #you know how long it took for me to realize i named it gird instead of grid, i think i did this in the other scenes too


func _on_random_pressed() -> void:
	for y in range(height):
		for x in range(width):
			grid[y][x] = randf() < 0.25
	draw_gird()
