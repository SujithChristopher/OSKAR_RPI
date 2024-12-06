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
var start_drawing : bool

var message = 'connected'

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

func _on_ready():
	_current_line = Line2D.new()
	_current_line.add_point(Vector2(600, 400))
	_lines.add_child(_current_line)



func _on_set_orgin_pressed():
	message = 'set_orgin'

func _on_start_pressed():
	message = 'start'
