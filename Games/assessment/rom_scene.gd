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

@onready var arrow_1: Node2D = $Arrow1
@onready var arrow_2: Node2D = $Arrow2
@onready var arrow_3: Node2D = $Arrow3

@onready var mouse_dot = preload("res://Games/assessment/mouse_dot.tscn")


@onready var arrow_sprites = [arrow_1, arrow_2, arrow_3]
@onready var current_index = 0

@onready var arom_polygon2D: Polygon2D = $RomPolygon
@onready var arom_polygons

func _on_ready():
	_current_line = Line2D.new()
	_current_line.add_point(Vector2(600, 400))
	print('arom',arom_polygon2D.bones)
	print(arom_polygon2D.polygon)
	arom_polygons = arom_polygon2D.polygon

func _process(delta):
	if _presssed:
		message = 'close'

	if _temp_message == 'saved':
		message = 'connect'

	if _temp_message == "starting":
		start_drawing = true

	else:
		network_position = GlobalScript.network_position

	if network_position != Vector2.ZERO and start_drawing:
		_current_line.width = 5
		_current_line.default_color = Color.RED
		_current_line.add_point(network_position)
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		add_mouse_dot()

	
func add_mouse_dot():
	#var _mdot = mouse_dot.instantiate()
	#add_child(_mdot)
	pass
	#arom_polygons[1] = get_viewport().get_mouse_position()
	#arom_polygon2D.polygon = arom_polygons

		
func _draw() -> void:
	pass
	
func _on_set_orgin_pressed():
	message = 'set_orgin'

func _on_start_pressed():
	message = 'start'


func _on_switch_pressed() -> void:
	current_index = (current_index + 1) % arrow_sprites.size()
	update_visibility()

func update_visibility():
	# Loop through all sprites and set visibility
	for i in range(arrow_sprites.size()):
		arrow_sprites[i].visible = (i == current_index)
