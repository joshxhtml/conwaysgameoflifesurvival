extends Node2D

@export var alive_tile := 1
@export var dead_tile :=  0

const width := 7
const height := 7

@onready var demogrid: TileMapLayer = $ColorRect/LifeLayer
@onready var tile_label: Label = $ColorRect/RuleLabel
@onready var desc_label: RichTextLabel = $ColorRect/Description
@onready var next_button: Button = $ColorRect/Next
@onready var skip_button: Button = $ColorRect/Skip

var grid:= []
var current_rule := 0 
var trans := false

var rules := [
	{
		"title": "Underpopulation",
		"desc" : "A live cell with fewer than 2 neighbors dies.",
		"setup": Callable(self, "underpopulation"),
	},
	{
		"title": "Survival",
		"desc" : "A live cell with 2 or 3 neighbors survives.",
		"setup": Callable(self, "survival"),
	},
	{
		"title": "Overpopulation",
		"desc" : "A live cell with more than 3 neighbors dies.",
		"setup": Callable(self, "overpopulation"),
	},
	{
		"title": "Reproduction",
		"desc" : "A dead cell with exactly 3 neighbors becomes alive.",
		"setup": Callable(self, "reproduction"),
	}
]
func _ready() -> void:
	clear_gird()
	play_rule()



func draw_grid():
	demogrid.clear()
	for y in range(height):
		for x in range(width):
			demogrid.set_cell(
				Vector2i(x,y), alive_tile if grid[y][x] else dead_tile,
				Vector2i.ZERO
			)

func clear_gird():
	grid.clear()
	for i in range(height):
		var row := []
		for x in range(width):
			row.append(false)
		grid.append(row)

func play_rule():
	trans = true
	clear_gird()
	
	var rule = rules[current_rule]
	tile_label.text = rule["title"]
	desc_label.text = "[center]%s[/center]" % rule["desc"]
	
	rule["setup"].call()
	draw_grid()
	
	await get_tree().create_timer(1.0).timeout
	life()
	trans = false
func life():
	var new_grid := []

	for y in range(height):
		var row := []
		for x in range(width):
			var neighbors := count_neighbors(x, y)
			var alive :bool= grid[y][x]
			var next := false

			if alive and (neighbors == 2 or neighbors == 3):
				next = true
			elif not alive and neighbors == 3:
				next = true

			row.append(next)
		new_grid.append(row)

	grid = new_grid
	draw_grid()
func count_neighbors(x: int, y: int) -> int:
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
func underpopulation():
	clear_gird()
	grid[3][3] = true
func survival():
	clear_gird()
	grid[3][3] = true
	grid[3][2] = true
	grid[3][4] = true
func overpopulation():
	clear_gird()
	grid[3][3] = true
	for dx in [-1,0,1]:
		for dy in [-1,1]:
			grid[3 +dy][3+dx] = true
func reproduction():
	clear_gird()
	grid[2][3] = true
	grid[3][2] = true
	grid[3][4] = true



func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://main_grid.tscn")

func _on_next_pressed() -> void:
	if trans:
		return
	
	current_rule += 1
	if current_rule >= rules.size():
		get_tree().change_scene_to_file("res://main_grid.tscn")
		return
	play_rule()
	
	
