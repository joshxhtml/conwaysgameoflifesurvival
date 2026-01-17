extends Node2D

const width := 7
const height := 7

var grid:= []

const rules := {
	underpopulation :{
		"title": "Underpopulation",
		"desc" : "A live cell with fewer than 2 neighbors dies.",
		"setup": func(): underpopulation()
	},
	survival :{
		"title": "Survival",
		"desc" : "A live cell with 2 or 3 neighbors survives.",
		"setup": func(): survival()
	},
	overpopulation :{
		"title": "Overpopulation",
		"desc" : "A live cell with more than 3 neighbors dies.",
		"setup": func(): overpopulation()
	},
	reproduction :{
		"title": "Reproduction",
		"desc" : "A dead cell with exactly 3 neighbors becomes alive.",
		"setup": func(): reproduction()
	}
}

func clear_gird():
	grid.clear()
	for i in range(height):
		var row := []
		for x in range(width):
			row.append(false)
		grid.append(row)

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
