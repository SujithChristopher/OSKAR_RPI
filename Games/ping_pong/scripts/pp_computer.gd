extends CharacterBody2D
const SPEED = 20000

#const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var ball = $"../Ball"

func _physics_process(delta):
    
    # Add the gravity.
    var direction = (ball.position - position).normalized()
    velocity.x = direction.x * SPEED * delta
    position.y = 20
    move_and_slide()

func _on_ready():
    pass
