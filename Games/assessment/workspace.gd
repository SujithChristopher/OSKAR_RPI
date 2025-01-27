extends Node2D

@onready var points = []
@onready var convex_hull_points = PackedVector2Array()

@onready var active_workspace = []
@onready var mouse_pos
@onready var inflated_workspace
@onready var mouse_pressed:bool = false
@onready var mouse_current_first:bool = false

@onready var mouse_current_pos
@onready var mouse_previous_pos


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
@onready var current_index = 0

@onready var sprite_positions
@onready var player_offset = Vector2.ZERO

@onready var active_pols
@onready var training_pols
@onready var axdir
@onready var azdir
@onready var txdir
@onready var tzdir

@onready var rect_points

var hull
func _ready():
	# Generate 100 random points for demonstration
	for i in range(100):
		active_workspace.append(Vector2(randi() % 400 + 350, randi() % 400 + 200))
		
	active_workspace = PackedVector2Array(Geometry2D.convex_hull(active_workspace))
	inflated_workspace = Geometry2D.convex_hull(inflate_polygon(active_workspace, -20))
	
	_current_line = Line2D.new()
	add_child(_current_line)
	
	
func _process(delta: float) -> void:

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
		_current_line.add_point(network_position + Vector2(100,200) - player_offset)
		
	if network_position != Vector2.ZERO:
		$Player.position = network_position  + Vector2(100,200) - player_offset
		
	if Input.is_action_just_released("mouse_left"):
		mouse_current_first = false
		mouse_pressed = false
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_pressed = true
		if not mouse_current_first:
			mouse_previous_pos = get_viewport().get_mouse_position()
			mouse_current_first = true
			
	if mouse_pressed:
		mouse_pos = (get_viewport().get_mouse_position() - mouse_previous_pos).length()
		if Geometry2D.is_point_in_polygon(get_viewport().get_mouse_position(), inflated_workspace):
			inflated_workspace = Geometry2D.convex_hull(inflate_polygon(active_workspace, -mouse_pos))
		queue_redraw()
	get_xy_cm()

func get_xy_cm():
	#print(get_aabb(active_workspace))
	active_pols = get_rect(active_workspace)
	
	axdir = abs(active_pols[0][0]-active_pols[1][0]) / GlobalScript.PLAYER_POS_SCALER_X*100
	azdir = abs(active_pols[0][1]-active_pols[1][1]) / GlobalScript.PLAYER_POS_SCALER_Y*100

	training_pols = get_rect(inflated_workspace)
	txdir = abs(training_pols[0][0]-training_pols[1][0]) / GlobalScript.PLAYER_POS_SCALER_X*100
	tzdir = abs(training_pols[0][1]-training_pols[1][1]) / GlobalScript.PLAYER_POS_SCALER_Y*100
	
	$VBoxContainer/HBoxContainer/axval.text = String("%.2f" % axdir)
	$VBoxContainer/HBoxContainer3/azval.text = String("%.2f" % azdir)
	$VBoxContainer/HBoxContainer2/txval.text = String("%.2f" % txdir)
	$VBoxContainer/HBoxContainer4/tzval.text = String("%.2f" % tzdir)
	
func inflate_polygon(polygon: Array, distance: float) -> Array:
	var inflated_polygon = []
	var len = polygon.size()


	for i in range(len):
		var current_point = polygon[i]
		var next_point = polygon[(i + 1) % len]

		# Compute the edge direction
		var edge_dir = (next_point - current_point).normalized()

		# Compute the perpendicular direction to the edge (outward)
		var perp_dir = Vector2(-edge_dir.y, edge_dir.x)

		# Offset the points by the distance along the perpendicular direction
		inflated_polygon.append(current_point + perp_dir * distance)
		inflated_polygon.append(next_point + perp_dir * distance)

	return inflated_polygon

func _draw() -> void:
	var hull_colors = PackedColorArray()
	hull_colors.append(Color(0.5, 0.5, 1.0, 0.8))
	
	var colors = PackedColorArray()
	colors.append(Color(0.5, 0.5, 1.0, 0.5)) 
	
	draw_polygon(active_workspace, hull_colors)
	draw_polygon(inflated_workspace, colors)
	
	rect_points = get_aabb(inflated_workspace)
	
	if rect_points:
		draw_rect(rect_points, Color(0.5, 0.5, 1.0, 0.8), false)

func reduce_to_seven_points(hull):
	var step = hull.size() / 7
	var reduced_hull = []
	for i in range(7):
		reduced_hull.append(hull[int(i * step)])
	return reduced_hull


func _on_start_pressed() -> void:
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


func _on_set_orgin_pressed() -> void:
	message = 'set_orgin'


func _on_clear_pressed() -> void:
	_current_line.clear_points()


func _on_select_game_pressed() -> void:
	GlobalSignals.inflated_workspace = inflated_workspace
	get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")
	
func get_rect(points):
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	var pac: PackedVector2Array = []
	pac.append(Vector2(min_x, min_y))
	pac.append(Vector2(max_x - min_x, max_y - min_y))
	return pac
	
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

func _on_stop_button_pressed() -> void:
	var aabb = get_aabb(_current_line.points)
	rect_points = aabb

	active_workspace = Geometry2D.convex_hull(_current_line.points)
	inflated_workspace = Geometry2D.convex_hull(inflate_polygon(active_workspace, -20))
	var prom_size = get_aabb(inflated_workspace).size
	GlobalSignals.global_scalar_x = get_viewport_rect().size.x /prom_size.x 
	GlobalSignals.global_scalar_y = get_viewport_rect().size.y /prom_size.y
