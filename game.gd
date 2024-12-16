extends Node2D

# Safe Game Area
const X_MIN = 1
const X_MAX = 22
const Y_MIN = 1
const Y_MAX = 10

# Atlas Coords for TileMap
const NOTHING  = Vector2i(-1, -1)
const HEAD_UP  = Vector2i(0, 0)
const HEAD_LEFT  = Vector2i(1, 0)
const HEAD_DOWN  = Vector2i(2, 0)
const HEAD_RIGHT  = Vector2i(3, 0)
const BODY  = Vector2i(4, 0)
const FOOD  = Vector2i(5, 0)
const GHOST  = Vector2i(7, 0)

const GHOST_COUNT = 4

var directions = {
	Vector2i.ZERO: {
		"sprite": HEAD_UP
	},
	Vector2i.UP: {
		"sprite": HEAD_UP,
		"action": "ui_up",
		"blocked_direction": Vector2i.DOWN
	},
	Vector2i.DOWN: {
		"sprite": HEAD_DOWN,
		"action": "ui_down",
		"blocked_direction": Vector2i.UP
	},
	Vector2i.LEFT: {
		"sprite": HEAD_LEFT,
		"action": "ui_left",
		"blocked_direction": Vector2i.RIGHT
	},
	Vector2i.RIGHT: {
		"sprite": HEAD_RIGHT,
		"action": "ui_right",
		"blocked_direction": Vector2i.LEFT
	}
}

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var score_label: Label = $ScoreLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var eat_food_sound: AudioStreamPlayer = $Audio/EatFoodSound
@onready var obnoxious_background_sound: AudioStreamPlayer = $Audio/ObnoxiousBackgroundSound
@onready var game_over_sound: AudioStreamPlayer = $Audio/GameOverSound

var direction := Vector2i.ZERO
var next_direction := Vector2i.ZERO
var positions: Array[Vector2i] = [Vector2i(X_MAX,Y_MAX)/2]
var ghost_positions: Array[Vector2i] = []

func _ready() -> void:	
	setup_game()
func _process(_delta: float) -> void:
	handle_input()

func setup_game():	
	update_head_sprite(direction)
	spawn_food()
	for n in GHOST_COUNT:
		spawn_ghost()
func restart_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Game.tscn")

# Loop over the direction dictionary and check if any of the "action"'s are pressed
# If so, make sure we're not navigating directly into the space we just came from when long
func handle_input():
	var is_long = positions.size() > 1
	for key in directions:
		var value = directions[key]
		if  (value.has("action") and Input.is_action_pressed(value.action)) \
		and (direction != value.blocked_direction if is_long else true):
			next_direction = key # Don't actually change directions until the next tick
			update_head_sprite(next_direction)
			break

func on_tick() -> void:	
	direction = next_direction
	if direction == Vector2i.ZERO: return
	
	var head_position := positions[0]
	var next_head_position := head_position + direction
	
	var is_dead = false
	var ate_food = false
	var tile_data = tile_map_layer.get_cell_tile_data(next_head_position)
	if tile_data != null:
		is_dead = tile_data.get_custom_data("kills_player")
		ate_food = tile_data.get_custom_data("food")
	
	if is_dead:
		game_over_label.show()
		obnoxious_background_sound.stop()
		game_over_sound.play()
		get_tree().paused = true
		return
	
	positions.push_front(next_head_position)
	update_head_sprite(direction)
	set_cell(head_position, BODY)
	
	if !ate_food:
		set_cell(positions.pop_back(), NOTHING) # Remove last position from tail
	else:
		spawn_food()
		eat_food_sound.play()
		score_label.text = "SCORE: %d" % (positions.size() - 1)

func spawn_food():
	var coord = get_empty_coord()
	set_cell(coord, FOOD)

#region Ghosts
func spawn_ghost():
	var coord = get_empty_coord()
	ghost_positions.push_back(coord)
	set_cell(coord, GHOST)
func get_next_ghost_coord(pos: Vector2i):
	var diffs = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	diffs.shuffle()
	for diff in diffs: 
		var coord = pos + diff
		if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
			return coord
	return pos
func update_ghosts():
	if direction == Vector2i.ZERO: return
	for i in ghost_positions.size():
		var pos: Vector2i = ghost_positions.pop_front()
		var new_pos = get_next_ghost_coord(pos)
		ghost_positions.push_back(new_pos)
		set_cell(pos, NOTHING)
		set_cell(new_pos, GHOST)
#endregion

#region Utils
func set_cell(coord: Vector2i, atlas: Vector2i):
	tile_map_layer.set_cell(coord, 0, atlas)
func update_head_sprite(dir: Vector2i):
	set_cell(positions[0], directions[dir].sprite)
func get_empty_coord():
	var options: Array[Vector2i] = []
	for x in range(X_MIN, X_MAX):
		for y in range(Y_MIN, Y_MAX):
			var coord = Vector2i(x, y)
			if tile_map_layer.get_cell_atlas_coords(coord) == NOTHING:
				options.push_back(coord)
	return options.pick_random()
#endregion
