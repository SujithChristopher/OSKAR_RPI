extends CharacterBody2D
class_name Ball

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var game_started: bool = false
var player_score = 0
var computer_score = 0
var status = ""
@export var INITIAL_BALL_SPEED = 15

@export var speed_multiplier = 1
@onready var player_score_label = $"../PlayerScore"
@onready var computer_score_label: Label = $"../ComputerScore"

var ball_speed = INITIAL_BALL_SPEED

func _physics_process(delta):
	if not game_started:
		return
	var collision = move_and_collide(velocity * ball_speed * delta)
	if(collision):
		var collider_name = collision.get_collider().name
		match collider_name:
			"bottom":
				computer_score += 1
				status = "ground"
			"top":
				player_score += 1
				status = "top"
			"left":
				status = "left"
			"right":
				status = "right"
			"player":
				status = "player"
			"computer":
				status = "computer"
		

			
		player_score_label.text = "Player " + str(player_score)
		computer_score_label.text = "Computer " + str(computer_score)
		velocity =  velocity.bounce(collision.get_normal()) * speed_multiplier
	else:
		status = "moving"
	
	GlobalSignals.ball_position = position
	

func _on_ready():
	start_ball() 
	
	
func start_ball():
	randomize()
	velocity.x = [-1, 1][randi() % 2] * INITIAL_BALL_SPEED
	velocity.y = [-.8, .8][randi() % 2] * INITIAL_BALL_SPEED
	
