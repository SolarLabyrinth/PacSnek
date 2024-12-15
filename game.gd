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

enum Facing {
	None,
	Left,
	Right,
	Up,
	Down
}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var label: Label = $ScoreLabel
@onready var game_over_label: Label = $GameOverLabel

var facing := Facing.None
var positions: Array[Vector2i] = [Vector2i(X_MAX/2,Y_MAX/2)]
var ghost_positions: Array[Vector2i] = []

func update_facing():
	var head_position = positions[0]
	match facing:
		Facing.Up, Facing.None:
			tile_map_layer.set_cell(head_position, 0, HEAD_UP)
		Facing.Left:
			tile_map_layer.set_cell(head_position, 0, HEAD_LEFT)
		Facing.Right:
			tile_map_layer.set_cell(head_position, 0, HEAD_RIGHT)
		Facing.Down:
			tile_map_layer.set_cell(head_position, 0, HEAD_DOWN)

func _ready() -> void:
	update_facing()
	spawn_food()
	for n in GHOST_COUNT:
		spawn_ghost()

func _process(delta: float) -> void:
	var is_long = positions.size() > 1
	if Input.is_action_just_pressed("ui_up") and (facing != Facing.Down if is_long else true):
		facing = Facing.Up
		update_facing()
	if Input.is_action_just_pressed("ui_down") and (facing != Facing.Up if is_long else true):
		facing = Facing.Down
		update_facing()
	if Input.is_action_just_pressed("ui_left") and (facing != Facing.Right if is_long else true):
		facing = Facing.Left
		update_facing()
	if Input.is_action_just_pressed("ui_right") and (facing != Facing.Left if is_long else true):
		facing = Facing.Right
		update_facing()

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
	if facing == Facing.None: return
	
	var head_position := positions[0]
	var next_head_position := head_position
	match facing:
		Facing.Up:
			next_head_position += Vector2i(0,-1)
		Facing.Left:
			next_head_position += Vector2i(-1,0)
		Facing.Right:
			next_head_position += Vector2i(1,0)
		Facing.Down:
			next_head_position += Vector2i(0,1)
			
	var is_collision = is_collision(next_head_position)
	var ate_food = is_food(next_head_position)
	
	if is_collision:
		game_over_label.show()
		get_tree().paused = true
		return
	
	positions.push_front(next_head_position)
	update_facing()
	tile_map_layer.set_cell(head_position, 0, BODY)
	
	if !ate_food:
		var tail_position: Vector2i = positions.pop_back()
		tile_map_layer.set_cell(tail_position, 0, NOTHING)
	else:
		spawn_food()
		label.text = "SCORE: " + str(positions.size() - 1)

func get_empty_coord():
	while true:
		var x = randi_range(X_MIN, X_MAX)
		var y = randi_range(Y_MIN, Y_MAX)
		var coord = Vector2i(x,y)
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			return coord
func get_ghost_movement(original_pos: Vector2i):
	var xs = [-1,0,1]
	xs.shuffle()
	for x in xs:
		var ys = [-1,0,1]
		ys.shuffle()
		for y in ys:
			var diff = Vector2i(x,y)
			var coord = original_pos + diff
			if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
				return coord
	return original_pos

func spawn_food():
	var coord = get_empty_coord()
	tile_map_layer.set_cell(coord, 0, FOOD)
func spawn_ghost():
	var coord = get_empty_coord()
	ghost_positions.push_back(coord)
	tile_map_layer.set_cell(coord, 0, GHOST)

func update_ghosts():
	if facing == Facing.None: return
	
	for i in ghost_positions.size():
		var original_pos: Vector2i = ghost_positions.pop_front()
		var new_pos = get_ghost_movement(original_pos)
		ghost_positions.push_back(new_pos)
		tile_map_layer.set_cell(original_pos, 0, NOTHING)
		tile_map_layer.set_cell(new_pos, 0, GHOST)

func on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Game.tscn")
