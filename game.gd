extends Node2D

const X_MIN = 1
const X_MAX = 22
const Y_MIN = 1
const Y_MAX = 10

const NOTHING  = Vector2i(-1, -1)
const HEAD_UP  = Vector2i(0, 0)
const HEAD_LEFT  = Vector2i(1, 0)
const HEAD_DOWN  = Vector2i(2, 0)
const HEAD_RIGHT  = Vector2i(3, 0)
const BODY  = Vector2i(4, 0)
const FOOD  = Vector2i(5, 0)
const GHOST  = Vector2i(7, 0)

const GHOST_COUNT = 4

enum Direction {
	None,
	Left,
	Right,
	Up,
	Down
}

var dirDictionary = {
	Direction.None: {
		"sprite": HEAD_UP
	},
	Direction.Up: {
		"sprite": HEAD_UP,
		"movement": Vector2i.UP,
		"action": "ui_up",
		"long_forbidden_direction": Direction.Down
	},
	Direction.Down: {
		"sprite": HEAD_DOWN,
		"movement": Vector2i.DOWN,
		"action": "ui_down",
		"long_forbidden_direction": Direction.Up
	},
	Direction.Left: {
		"sprite": HEAD_LEFT,
		"movement": Vector2i.LEFT,
		"action": "ui_left",
		"long_forbidden_direction": Direction.Right
	},
	Direction.Right: {
		"sprite": HEAD_RIGHT,
		"movement": Vector2i.RIGHT,
		"action": "ui_right",
		"long_forbidden_direction": Direction.Left
	}
}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var score_label: Label = $ScoreLabel
@onready var game_over_label: Label = $GameOverLabel

var direction := Direction.None
var positions: Array[Vector2i] = [Vector2i(X_MAX,Y_MAX)/2]
var ghost_positions: Array[Vector2i] = []

func set_cell(coord: Vector2i, atlas: Vector2i):
	tile_map_layer.set_cell(coord, 0, atlas)

func update_head_sprite():
	set_cell(positions[0], dirDictionary[direction].sprite)
func update_tail_sprite():
	set_cell(positions.pop_back(), NOTHING)

func _ready() -> void:	
	update_head_sprite()
	spawn_food()
	for n in GHOST_COUNT:
		spawn_ghost()

func _process(delta: float) -> void:
	var is_long = positions.size() > 1
	for key in dirDictionary:
		var value = dirDictionary[key]
		if  (value.has("action") and Input.is_action_just_pressed(value.action)) \
		and (direction != value.long_forbidden_direction if is_long else true):
			direction = key
			update_head_sprite()
			break

func is_collision(coord: Vector2i) -> bool:
	var data = tile_map_layer.get_cell_tile_data(coord)
	if data == null: return false
	var is_collision = data.get_custom_data("wall") or data.get_custom_data("snake") or data.get_custom_data("ghost")
	return is_collision
func is_food(coord: Vector2i) -> bool:
	var data = tile_map_layer.get_cell_tile_data(coord)
	if data == null: return false
	var ate_food = data.get_custom_data("food")
	return ate_food

func on_tick() -> void:	
	if direction == Direction.None: return
	
	var head_position := positions[0]
	var next_head_position: Vector2i = head_position + dirDictionary[direction].movement
	
	var is_collision = is_collision(next_head_position)
	var ate_food = is_food(next_head_position)
	
	if is_collision:
		game_over_label.show()
		get_tree().paused = true
		return
	
	positions.push_front(next_head_position)
	update_head_sprite()
	set_cell(head_position, BODY)
	
	if !ate_food:
		update_tail_sprite()
	else:
		spawn_food()
		score_label.text = "SCORE: " + str(positions.size() - 1)

func get_empty_coord():
	while true:
		var x = randi_range(X_MIN, X_MAX)
		var y = randi_range(Y_MIN, Y_MAX)
		var coord = Vector2i(x,y)
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			return coord

func get_ghost_movement(original_pos: Vector2i):
	var diffs = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	diffs.shuffle()
	for diff in diffs: 
		var coord = original_pos + diff
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			return coord
	return original_pos

func spawn_food():
	var coord = get_empty_coord()
	set_cell(coord, FOOD)
func spawn_ghost():
	var coord = get_empty_coord()
	ghost_positions.push_back(coord)
	set_cell(coord, GHOST)

func update_ghosts():
	if direction == Direction.None: return
	
	for i in ghost_positions.size():
		var original_pos: Vector2i = ghost_positions.pop_front()
		var new_pos = get_ghost_movement(original_pos)
		ghost_positions.push_back(new_pos)
		set_cell(original_pos, NOTHING)
		set_cell(new_pos, GHOST)

func on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Game.tscn")
