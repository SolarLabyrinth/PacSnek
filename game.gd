extends Node2D

const NOTHING  = Vector2i(-1, -1)
const HEAD_UP  = Vector2i(0, 0)
const HEAD_LEFT  = Vector2i(1, 0)
const HEAD_DOWN  = Vector2i(2, 0)
const HEAD_RIGHT  = Vector2i(3, 0)
const BODY  = Vector2i(4, 0)
const FOOD  = Vector2i(5, 0)
const BOUNDRY  = Vector2i(6, 0)

enum Facing {
	Left,
	Right,
	Up,
	Down
}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var facing := Facing.Right
var positions: Array[Vector2i] = [Vector2i(3,3)]

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
	var head_position = positions[0]
	print(tile_map_layer.tile_set.get_source_id(0))
	print(tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)))
	print(tile_map_layer.get_cell_atlas_coords(Vector2i(1, 1)))
	update_facing()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
		print("Game Over")
		return
	
	positions.push_front(next_head_position)
	update_facing()
	tile_map_layer.set_cell(head_position, 0, BODY)
	
	if !ate_food:
		var tail_position: Vector2i = positions.pop_back()
		tile_map_layer.set_cell(tail_position, 0, NOTHING)
	else:
		spawn_food()
	
	
		
func spawn_food():
	while true:
		var x = randi_range(1,22)
		var y = randi_range(1,10)
		var coord = Vector2i(x,y)
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			tile_map_layer.set_cell(coord, 0, FOOD)
			break
