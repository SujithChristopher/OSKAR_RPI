extends Polygon2D


@onready var current_vertex:int 
@onready var vertex_selected:bool = false
@onready var rom_polygon: Polygon2D = $"."

@onready var poly_vals
@onready var vertex_clicked:bool = false
@onready var mouse_pos_normalized
@onready var player_pos = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
@onready var aw_poly_vals

func _ready() -> void:
	poly_vals = rom_polygon.polygon
		
	$TWLabel.position.y = poly_vals[1][1]
	$TWLabel.position.x = poly_vals[1][0] + (poly_vals[2][0] - poly_vals[1][0])/2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		$TWLabel.position.y = poly_vals[1][1]
		$TWLabel.position.x = poly_vals[1][0] + (poly_vals[2][0] - poly_vals[1][0])/2
		
		player_pos = get_viewport().get_mouse_position()
		if vertex_selected and current_vertex == 0:
			poly_vals[0] = player_pos
			poly_vals[1].x = player_pos.x
			poly_vals[3].y = player_pos.y
			rom_polygon.polygon = poly_vals
			$v1.position = player_pos
			$v1/Sprite2D.position = $v1/CollisionShape2D.position
			
			$v2.position.x = player_pos.x
			$v2/Sprite2D.position.y = $v2/CollisionShape2D.position.y
			
			$v4.position.y = player_pos.y
			$v4/Sprite2D.position.y = $v4/CollisionShape2D.position.y
			
		elif vertex_selected and current_vertex == 1:
			poly_vals[1] = player_pos
			poly_vals[0].x = player_pos.x
			poly_vals[2].y = player_pos.y
			rom_polygon.polygon = poly_vals
			$v2.position = player_pos
			$v2/Sprite2D.position = $v2/CollisionShape2D.position
			
			$v3.position.y = player_pos.y
			$v3/Sprite2D.position.y = $v3/CollisionShape2D.position.y
			
			$v1.position.x = player_pos.x
			$v1/Sprite2D.position.x = $v1/CollisionShape2D.position.x

			
		elif vertex_selected and current_vertex == 2:
			poly_vals[2] = player_pos
			poly_vals[3].x = player_pos.x
			poly_vals[1].y = player_pos.y

			rom_polygon.polygon = poly_vals
			$v3.position = player_pos
			$v3/Sprite2D.position = $v3/CollisionShape2D.position
			
			$v2.position.y = player_pos.y
			$v2/Sprite2D.position.y = $v2/CollisionShape2D.position.y
			
			$v4.position.x = player_pos.x
			$v4/Sprite2D.position.x = $v4/CollisionShape2D.position.x
			
		elif vertex_selected and current_vertex == 3:
			
			poly_vals[3] = player_pos
			poly_vals[2].x = player_pos.x
			poly_vals[0].y = player_pos.y
			rom_polygon.polygon = poly_vals
			
			$v4.position = player_pos
			$v4/Sprite2D.position = $v4/CollisionShape2D.position
			
			$v3.position.x = player_pos.x
			$v3/Sprite2D.position.y = $v3/CollisionShape2D.position.y
			
			$v1.position.y = player_pos.y
			$v1/Sprite2D.position.y = $v1/CollisionShape2D.position.y
	
func _on_v_1_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 0
	
func _on_v_3_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 2

func _on_v_1_mouse_exited() -> void:
	vertex_selected = false
	current_vertex = -1

func _on_v_3_mouse_exited() -> void:
	vertex_selected = false
	current_vertex = -1

func _on_v_2_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 1

func _on_v_4_mouse_entered() -> void:
	vertex_selected = true
	current_vertex = 3

func _on_v_4_mouse_exited() -> void:
	vertex_selected = true
	current_vertex = -1

func _on_v_2_mouse_exited() -> void:
	vertex_selected = true
	current_vertex = -1
