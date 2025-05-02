extends CharacterBody2D
class_name Ball


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var game_started: bool = false
var player_score = 0
var computer_score = 0
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

		if collision.get_collider().name == 'bottom':
			computer_score += 1
		if collision.get_collider().name == 'player':
			player_score += 1
		player_score_label.text = "Player " + str(player_score)
		computer_score_label.text = "Computer " + str(computer_score)
		velocity =  velocity.bounce(collision.get_normal()) * speed_multiplier
		
		#if collision.get_collider() is Paddle:
			##audio_stream_player.play()
	GlobalSignals.ball_position = position

func _on_ready():
	start_ball() 
	
func start_ball():
	randomize()
	velocity.x = [-1, 1][randi() % 2] * INITIAL_BALL_SPEED
	velocity.y = [-.8, .8][randi() % 2] * INITIAL_BALL_SPEED
