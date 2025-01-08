extends Node2D

signal thread_id
@onready var _lines := $Lines

var received_message
var thread: Thread
var the_message : String

var connected = false
var network_position

var _temp_message
var _presssed = false

var _current_line : Line2D
var current_polyline: Line2D

var start_drawing : bool

var message = 'connected'
@onready var start_pressed:bool = true

@onready var arrow_1: Node2D = $RomPolygon/Arrow1
@onready var arrow_2: Node2D = $RomPolygon/Arrow2
@onready var arrow_3: Node2D = $RomPolygon/Arrow3

@onready var mouse_dot = preload("res://Games/assessment/mouse_dot.tscn")


@onready var arrow_sprites = [arrow_1, arrow_2, arrow_3]
@onready var current_index = 0

@onready var arom_polygon2D: Polygon2D = $AromPolygon
@onready var arom_polygons
@onready var rom_polygon: Polygon2D = $RomPolygon
@onready var sprite_positions
@onready var player_offset = Vector2.ZERO

@onready var active_pols
@onready var training_pols
@onready var axdir
@onready var azdir
@onready var txdir
@onready var tzdir

func _on_ready():
	_current_line = Line2D.new()
	#_current_line.add_point(Vector2(600, 400))

	arom_polygons = arom_polygon2D.polygon
	add_child(_current_line)
	

func _process(delta):
	if _presssed:
		message = 'close'

	if _temp_message == 'saved':
		message = 'connect'

	if _temp_message == "starting":
		start_drawing = true
	
	network_position = GlobalScript.network_position

	if network_position != Vector2.ZERO and start_drawing:
		_current_line.width = 5
		_current_line.default_color = Color.RED
		_current_line.add_point(network_position - Vector2(300,300) - player_offset)
		
	if network_position != Vector2.ZERO:
		$Player.position = network_position  - Vector2(300,300) - player_offset

	get_xy_cm()


func get_xy_cm():
	active_pols = $AromPolygon.polygon
	axdir = abs(active_pols[0][0]-active_pols[1][0]) / GlobalScript.PLAYER_POS_SCALER_X*100
	azdir = abs(active_pols[0][1]-active_pols[3][1]) / GlobalScript.PLAYER_POS_SCALER_Y*100

	training_pols = $RomPolygon.polygon
	txdir = abs(training_pols[0][0]-training_pols[3][0]) / GlobalScript.PLAYER_POS_SCALER_X*100
	tzdir = abs(training_pols[0][1]-training_pols[1][1]) / GlobalScript.PLAYER_POS_SCALER_Y*100
	
	$VBoxContainer/HBoxContainer/axval.text = String("%.2f" % axdir)
	$VBoxContainer/HBoxContainer3/azval.text = String("%.2f" % azdir)
	$VBoxContainer/HBoxContainer2/txval.text = String("%.2f" % txdir)
	$VBoxContainer/HBoxContainer4/tzval.text = String("%.2f" % tzdir)

func get_aabb(points):
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))	
	

func _draw_polygon(polygon_points):
	$AromPolygon.show()
	$RomPolygon.show()
	arom_polygon2D.polygon = polygon_points
	
	var _vector_offset = 20
	
	var offsets = [
		Vector2(-_vector_offset, -_vector_offset),
		Vector2(_vector_offset, -_vector_offset),
		Vector2(_vector_offset, _vector_offset),
		Vector2(-_vector_offset, _vector_offset),
	]	

	sprite_positions =  elementwise_add(polygon_points, offsets)
	rom_polygon.polygon[0] = sprite_positions[3]
	rom_polygon.polygon[1] = sprite_positions[0]
	rom_polygon.polygon[2] = sprite_positions[1]
	rom_polygon.polygon[3] = sprite_positions[2]
	
	$RomPolygon/TWLabel.position.y = rom_polygon.polygon[1][1]
	$RomPolygon/TWLabel.position.x = rom_polygon.polygon[1][0] + (rom_polygon.polygon[2][0] - rom_polygon.polygon[1][0])/2
	
	$AromPolygon/AWLabel.position.y = $AromPolygon.polygon[1][1]
	$AromPolygon/AWLabel.position.x = $AromPolygon.polygon[1][0] + ($AromPolygon.polygon[3][0] - $AromPolygon.polygon[1][0])/2

	$RomPolygon/v1.position = sprite_positions[3]
	$RomPolygon/v1/Sprite2D.position = $RomPolygon/v1/CollisionShape2D.position

	$RomPolygon/v2.position = sprite_positions[0]
	$RomPolygon/v2/Sprite2D.position = $RomPolygon/v2/CollisionShape2D.position
	
	$RomPolygon/v3.position = sprite_positions[1]
	$RomPolygon/v3/Sprite2D.position = $RomPolygon/v3/CollisionShape2D.position
	#
	$RomPolygon/v4.position = sprite_positions[2]
	$RomPolygon/v4/Sprite2D.position = $RomPolygon/v4/CollisionShape2D.position

func elementwise_add(list1: Array, list2: Array) -> Array:
	var result = []
	
	for i in range(4):
		result.append(list1[i] + list2[i])
	
	return result


func add_mouse_dot():
	pass
	
func _on_set_orgin_pressed():
	message = 'set_orgin'

func _on_start_pressed():
	message = 'start'
	start_pressed = !start_pressed
	
	if start_pressed:
		start_drawing = false
		start_pressed = true
		$start.text = "Start"
	else:
		start_drawing = true
		start_pressed = false
		$start.text = "Stop"


func _on_switch_pressed() -> void:
	current_index = (current_index + 1) % arrow_sprites.size()
	update_visibility()

func update_visibility():
	# Loop through all sprites and set visibility
	for i in range(arrow_sprites.size()):
		arrow_sprites[i].visible = (i == current_index)

	
func _on_stop_button_pressed() -> void:
	var aabb = get_aabb(_current_line.points)
	var polygon_points = [
		aabb.position,                              # Top-left
		aabb.position + Vector2(aabb.size.x, 0),    # Top-right
		aabb.position + aabb.size,                  # Bottom-right
		aabb.position + Vector2(0, aabb.size.y)     # Bottom-left
	]

	_draw_polygon(polygon_points)

	var prom_size = get_aabb(rom_polygon.polygon).size
	GlobalSignals.global_scalar_x = get_viewport_rect().size.x /prom_size.x 
	GlobalSignals.global_scalar_y = get_viewport_rect().size.y /prom_size.y

func _on_select_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")


func _on_clear_pressed() -> void:
	_current_line.clear_points()


func _on_reset_pressed() -> void:
	_current_line.clear_points()
	player_offset = - network_position
	
