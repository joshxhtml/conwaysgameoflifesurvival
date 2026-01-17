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
@onready var bg := $RoundUi/UIBackground
@onready var round_label := $RoundUi/UIBackground/RoundChangeLabel
@onready var shop_holder := $RoundUi/UIBackground/ShopInfoHolder
@onready var powerup_button_1 := $RoundUi/UIBackground/ShopInfoHolder/Powerup1
@onready var powerup_button_2 := $RoundUi/UIBackground/ShopInfoHolder/Powerup2
@onready var continue_button := $RoundUi/UIBackground/ShopInfoHolder/Continue
@onready var powerup_button_1_label : RichTextLabel = powerup_button_1.get_node("RichTextLabel") 
@onready var powerup_button_2_label : RichTextLabel = powerup_button_2.get_node("RichTextLabel")

var grid: Array = []
var player_position: Vector2i
var is_player_alive:= true
var going_from_left_to_right: bool = false
var showing_the_round_num_screen: bool = false
var in_shop := false

var roundnum : int = 0
var points := 0

#trying a new powerup system instead of making like 50 resoucres (cough cough skee ball)
enum powerup_type {
	MOVE_2,
}
const POWERUP_INFO := {
	powerup_type.MOVE_2: {
		"name": "Double Step",
		"description": "First move is free. Life updates after the second move.",
		"cost": 1,
	}
}
var owned_powerups: Array[powerup_type] = []
var extra_move := 0
var shop_item: Array[powerup_type] = []


func _ready():
	randomize()
	
	powerup_button_1.pressed.connect(func(): buy_powerup(0))
	powerup_button_2.pressed.connect(func(): buy_powerup(1))
	continue_button.pressed.connect(close_shop)
	
	var viewport_size: Vector2i = get_viewport().get_visible_rect().size
	@warning_ignore("integer_division")
	width = viewport_size.x /16
	@warning_ignore("integer_division")
	height = viewport_size.y / 16
	
	shop_holder.visible = false
	ui.visible = false
	
	initialize_grid()
	@warning_ignore("integer_division")
	spawn_player(height/2)
	draw_said_grid()
	draw_start_and_goal()
	draw_player()
	advance()

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
	if new_pos.x < 0 or new_pos.x >= width: return
	if new_pos.y < 0 or new_pos.y >= height: return
		
	player_position = new_pos
	
	if extra_move > 0:
		extra_move -= 1
	else:
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

#round changer
func advance():
	showing_the_round_num_screen = true
	roundnum += 1
	points += 1
	going_from_left_to_right= !going_from_left_to_right
	
	if roundnum % 1 == 0:
		await open_shop()
		return
	
	round_label.visible = true
	round_label.text = "round %d" % roundnum
	await fade_in()
	
	await get_tree().create_timer(1.0).timeout
	reset_grid()
	await fade_out()
	
	#ui.visible = false
	showing_the_round_num_screen = false

#grid things
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

#rules and callings
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

# ui stuff
func fade_in():
	ui.visible = true
	bg.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(bg, "modulate:a", 1.0, 0.4)
	await tween.finished
func fade_out():
	var tween2 :=  create_tween()
	tween2.tween_property(bg, "modulate:a", 0.0, 0.4)
	await tween2.finished
	
	ui.visible = false

#shop stuff
func open_shop():
	in_shop = true
	showing_the_round_num_screen = true
	round_label.visible = false
	shop_holder.visible = true
	
	shop_item.clear()
	while shop_item.size() < 2:
		var p : powerup_type= POWERUP_INFO.keys().pick_random()
		shop_item.append(p)
	
	update_shop_buttons()
	await fade_in()

func update_shop_buttons():
	for i in range(2):
		var p := shop_item[i]
		var info : Dictionary= POWERUP_INFO[p]
		var label : RichTextLabel = (powerup_button_1_label if i ==1 else powerup_button_2_label)
		var color:= "yellow" if points > info["cost"] else "red"
		label.clear()
		
		label.append_text(
	(
		"[center]"
		+ "[font_size=10][b]%s[/b][/font_size]\n"
		+ "[font_size=6]%s[/font_size]\n\n"
		+ "[color=%s][font_size=7]Cost: %d[/font_size][/color]"
		+ "[/center]"
	)
	% [
		info["name"],
		info["description"],
		color,
		info["cost"]
	]
)
func buy_powerup(index: int):
	if index >= shop_item.size():
		return
	
	var p := shop_item[index]
	var info: Dictionary = POWERUP_INFO[p]
	var cost: int = info["cost"]
	
	if points < cost:
		return
	
	points -= cost
	owned_powerups.append(p)
	
	if p == powerup_type.MOVE_2:
		extra_move += 1
		
	update_shop_buttons()

func close_shop():
	in_shop = false
	showing_the_round_num_screen = false
	shop_holder.visible = false
	
	reset_grid()
	await fade_out()

#powerup stuff
func has_powerup(p: powerup_type) -> bool:
	return p in owned_powerups

#input stuff, and by stuff i mean one function, godot makes input so easy
func _input(event: InputEvent) -> void:
	if showing_the_round_num_screen:
		return
	if in_shop:
		return
	
	if event.is_action_pressed("ui_up"):
		move_player(Vector2i(0,-1))
	elif event.is_action_pressed("ui_down"):
		move_player(Vector2i(0,1))
	elif event.is_action_pressed("ui_left"):
		move_player(Vector2i(-1,0))
	elif event.is_action_pressed("ui_right"):
		move_player(Vector2i(1,0)) 
