extends Polygon2D


@onready var current_vertex:int 
@onready var vertex_selected:bool = false
@onready var rom_polygon: Polygon2D = $"."

@onready var poly_vals
@onready var vertex_clicked:bool = false
@onready var mouse_pos_normalized
@onready var player_pos = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	poly_vals = rom_polygon.polygon


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		player_pos = get_viewport().get_mouse_position()
		
		if vertex_selected and current_vertex == 1:
			poly_vals[1] = player_pos
			poly_vals[0].x = player_pos.x
			rom_polygon.polygon = poly_vals
			$v1.position = player_pos
			$v1/Sprite2D.position = $v1/CollisionShape2D.position
			
		elif vertex_selected and current_vertex == 2:
			poly_vals[2] = player_pos
			rom_polygon.polygon = poly_vals
			$v2.position = player_pos
			$v2/Sprite2D2.position = $v2/CollisionShape2D.position
		elif vertex_selected and current_vertex == 3:
			poly_vals[3] = player_pos
			poly_vals[4].x = player_pos.x
			rom_polygon.polygon = poly_vals
			$v3.position = player_pos
			$v3/Sprite2D4.position = $v3/CollisionShape2D.position

func _on_v_1_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 1
	
func _on_v_2_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 2

func _on_v_3_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 3

func _on_v_1_mouse_exited() -> void:
	vertex_selected = false
	current_vertex = -1


func _on_v_2_mouse_exited() -> void:
	vertex_selected = false
	current_vertex = -1

func _on_v_3_mouse_exited() -> void:
	vertex_selected = false
	current_vertex = -1
