extends Node2D
#there goes fitting it all in one script
#i have a sense of deja vu
@export var alive_tile := 1
@export var dead_tile := 0
@export var cell_size := 16
@export var minimum_alive_before_you_get_flashbanged_lmao := 15

@onready var life_layer : TileMapLayer = $LifeLayer
@onready var flash_of_death: ColorRect = $WhiteFlashOfDeath

var width: int
var height : int
var grid: Array = []

func _ready() -> void:
	randomize()
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /cell_size
	@warning_ignore("integer_division")
	height = viewport_size.y / cell_size
	
	flash_of_death.visible = false
	intialize_grid()
	draw_said_grid()
	_run_life_loop_forever_and_ever()

func _run_life_loop_forever_and_ever() -> void:
	while true: #i LOVE infinite loops
		await get_tree().create_timer(0.15).timeout
		life()

func intialize_grid():
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
			life_layer.set_cell(
				Vector2i(x, y),
				alive_tile if grid[y][x] else dead_tile,
				Vector2i.ZERO
			)
			
func life():
	var new_grid : Array= []
	var alive_count := 0

	for y in range(height):
		var row : Array[bool]= []
		for x in range(width):
			var neighbors :int= count_neighbors(x, y)
			var alive :bool= grid[y][x]
			var next : bool= false

			if alive and (neighbors == 2 or neighbors == 3):
				next = true
			elif not alive and neighbors == 3:
				next = true
			if next:
				alive_count += 1
			
			row.append(next)
		new_grid.append(row)

	grid = new_grid
	draw_said_grid()

	if alive_count < minimum_alive_before_you_get_flashbanged_lmao:
		await flash_and_reset()

func count_neighbors(x: int, y: int) -> int:
	var count := 0
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx : int= (x + dx + width) % width
			var ny :int = (y + dy + height) % height
			if grid[ny][nx]:
				count += 1
	return count


func flash_and_reset():
	flash_of_death.visible = true
	flash_of_death.modulate.a = 0.0
	
	var getflashedfucker := create_tween()
	getflashedfucker.tween_property(flash_of_death, "modulate:a", 1.0, 0.1)
	getflashedfucker.tween_property(flash_of_death, "modulate:a", 0.0, 0.2)
	await getflashedfucker.finished
	
	flash_of_death.visible = false
	intialize_grid()
	draw_said_grid()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main_grid.tscn")
