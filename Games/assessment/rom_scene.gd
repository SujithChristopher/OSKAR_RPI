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

@onready var arrow_1: Node2D = $RomPolygon/Arrow1
@onready var arrow_2: Node2D = $RomPolygon/Arrow2
@onready var arrow_3: Node2D = $RomPolygon/Arrow3

@onready var mouse_dot = preload("res://Games/assessment/mouse_dot.tscn")


@onready var arrow_sprites = [arrow_1, arrow_2, arrow_3]
@onready var current_index = 0

@onready var arom_polygon2D: Polygon2D = $AromPolygon
@onready var arom_polygons
@onready var rom_polygon: Polygon2D = $RomPolygon

func _on_ready():
	_current_line = Line2D.new()
	_current_line.add_point(Vector2(600, 400))

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
		_current_line.add_point(network_position)
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		add_mouse_dot()

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
	#var _polygon_points = polygon_points.map(func(p): p + Vector2(5, 0) )
	arom_polygon2D.polygon = polygon_points

func add_mouse_dot():
	#var _mdot = mouse_dot.instantiate()
	#add_child(_mdot)
	#pass
	#arom_polygons[1] = get_viewport().get_mouse_position()
	#arom_polygon2D.polygon = arom_polygons
	pass

	
func _on_set_orgin_pressed():
	message = 'set_orgin'

func _on_start_pressed():
	message = 'start'
	start_drawing = true

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
