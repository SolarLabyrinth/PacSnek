extends Node2D

const NOTHING  = Vector2i(-1, -1)
const HEAD_UP  = Vector2i(0, 0)
const HEAD_LEFT  = Vector2i(1, 0)
const HEAD_DOWN  = Vector2i(2, 0)
const HEAD_RIGHT  = Vector2i(3, 0)
const BODY  = Vector2i(4, 0)
const FOOD  = Vector2i(5, 0)
const BOUNDRY  = Vector2i(6, 0)
const GHOST  = Vector2i(7, 0)

enum Facing {
	Left,
	Right,
	Up,
	Down
}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var label: Label = $Label

var running := true
var facing := Facing.Right
var positions: Array[Vector2i] = [Vector2i(3,3)]

var ghost_positions: Array[Vector2i] = [Vector2i(3,3)]

func update_facing():
	var head_position = positions[0]
	match facing:
		Facing.Up:
			tile_map_layer.set_cell(head_position, 0, HEAD_UP)
		Facing.Left:
			tile_map_layer.set_cell(head_position, 0, HEAD_LEFT)
		Facing.Right:
			tile_map_layer.set_cell(head_position, 0, HEAD_RIGHT)
		Facing.Down:
			tile_map_layer.set_cell(head_position, 0, HEAD_DOWN)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_facing()
	spawn_food()
	spawn_ghost()
	spawn_ghost()
	spawn_ghost()
	spawn_ghost()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!running): return
	
	if Input.is_action_just_pressed("ui_up"):
		facing = Facing.Up
		update_facing()
	if Input.is_action_just_pressed("ui_down"):
		facing = Facing.Down
		update_facing()
	if Input.is_action_just_pressed("ui_left"):
		facing = Facing.Left
		update_facing()
	if Input.is_action_just_pressed("ui_right"):
		facing = Facing.Right
		update_facing()

func on_tick() -> void:
	if(!running): return
	
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
	
	var next_cell_contents := tile_map_layer.get_cell_atlas_coords(next_head_position)
	var ate_food := next_cell_contents == FOOD
	var is_collision := next_cell_contents == BOUNDRY or next_cell_contents == BODY
	
	if is_collision:
		label.text = "GAME OVER. YOUR SCORE WAS: " + str(positions.size() - 1)
		running = false
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
		var x = randi_range(1,22)
		var y = randi_range(1,10)
		var coord = Vector2i(x,y)
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			return coord

func spawn_food():
	var coord = get_empty_coord()
	tile_map_layer.set_cell(coord, 0, FOOD)
func spawn_ghost():
	var coord = get_empty_coord()
	ghost_positions.push_back(coord)
	tile_map_layer.set_cell(coord, 0, GHOST)

func update_ghosts():
	for i in ghost_positions.size():
		var original_pos: Vector2i = ghost_positions.pop_front()
		var new_pos = original_pos + Vector2i(randi_range(-1,1), randi_range(-1,1))
		ghost_positions.push_back(new_pos)
		tile_map_layer.set_cell(original_pos, 0, NOTHING)
		tile_map_layer.set_cell(new_pos, 0, GHOST)
		pass