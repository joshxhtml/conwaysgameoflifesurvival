extends Node2D

@export var cell_size := 16
@export var alive_tile := 1
@export var dead_tile := 0
@onready var life_layer : TileMapLayer = $LifeLayer
@onready var playbutton := $UI/ColorRect/Play

var width : int 
var height : int


var grid := []
var running := false
var time 

func _ready() -> void:
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /cell_size
	@warning_ignore("integer_division")
	height = (viewport_size.y / 16) + 3
	$UI/ColorRect/SpeedSlider.value = 7.5
	time = 1.0/ $UI/ColorRect/SpeedSlider.value
	intialize()
	draw_gird()

func _process(delta: float) -> void:
	#print($UI/ColorRect/SpeedSlider.value)
	if running: 
		time -= delta
		if time <= 0:
			life()
			time =  1.0 / $UI/ColorRect/SpeedSlider.value

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
	if running:
		time = 1.0 / $UI/ColorRect/SpeedSlider.value
		playbutton.text = "Pause"
	else:
		playbutton.text = "Play"



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


#input 
var is_mouse_down := false
var last_cell_drawn := Vector2i(-1,-1)
var can_earse := true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_down = event.pressed
			last_cell_drawn = Vector2i(-1,-1)
			if is_mouse_down:
				draw_cell(event.position)
	elif event is InputEventMouseMotion and is_mouse_down:
		draw_cell(event.position)
	
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://main_menu.tscn")

func draw_cell(pos : Vector2):
	var cell_to_draw := life_layer.local_to_map(life_layer.to_local(pos))
	
	if not in_bounds(cell_to_draw):
		return
	
	#if last_cell_drawn == cell_to_draw:
	#	can_earse = not grid[cell_to_draw.y][cell_to_draw.x]
	
	grid[cell_to_draw.y][cell_to_draw.x] = true
	last_cell_drawn = cell_to_draw
	draw_gird()
