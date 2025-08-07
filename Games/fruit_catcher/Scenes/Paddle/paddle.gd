extends Area2D

const INITIAL_PADDLE_SPEED: float = 700.0
var MIN_X_VALUE: float
var MAX_X_VALUE: float
#const MIN_X_VALUE = get_viewport_rect().position.x
#const MAX_X_VALUE = get_viewport_rect().end.x

func _init() -> void:
    print("Paddle:: _init")
    
func _enter_tree() -> void:
    print("Paddle:: _enter_tree")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    print("Paddle:: _ready")
    MIN_X_VALUE = get_viewport_rect().position.x
    MAX_X_VALUE = get_viewport_rect().end.x
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    
    var movement: float = Input.get_axis("Left", "Right")
    position.x += INITIAL_PADDLE_SPEED * delta * movement
    
    position.x = clampf(
        position.x,
        MIN_X_VALUE,
        MAX_X_VALUE
    )
