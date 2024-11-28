extends CharacterBody2D
class_name Ball

const SPEED = 60.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var score = 0
@export var INITIAL_BALL_SPEED = 15

@export var speed_multiplier = 1
@onready var score_label = $"../Label"
var ball_speed = INITIAL_BALL_SPEED

func _physics_process(delta):
	var collision = move_and_collide(velocity * ball_speed * delta)

		
	if(collision):
		if collision.get_collider_id() == 29628564740:
			score -= 1
		if collision.get_collider_id() == 29595010306:
			score +=1
		score_label.text = "Score " + str(score)
		velocity =  velocity.bounce(collision.get_normal()) * speed_multiplier
		
		#if collision.get_collider() is Paddle:
			##audio_stream_player.play()


func _on_ready():
	start_ball() # Replace with function body.
	
func start_ball():
	randomize()
	velocity.x = [-1, 1][randi() % 2] * INITIAL_BALL_SPEED
	velocity.y = [-.8, .8][randi() % 2] * INITIAL_BALL_SPEED
