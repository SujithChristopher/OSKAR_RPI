extends Node2D

const EXPLODE = preload("res://Games/fruit_catcher/assets/explode.wav")
const GEM = preload("res://Games/fruit_catcher/Scenes/Fruits/fruit.tscn")
const MARGIN: float = 70.0
var START_OF_SCREEN_X: float
var END_OF_SCREEN_X: float

@onready var spawn_timer: Timer = $SpawnTimer
@onready var paddle: Area2D = $Paddle
@onready var score_sound: AudioStreamPlayer2D = $ScoreSound
@onready var sound: AudioStreamPlayer = $Sound
@onready var score_label: Label = $ScoreLabel
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var game_over_label: Label = $GameOverLabel

var _score: int = 0
var current_gem: Gem = null  
var game_active: bool = true

func _init() -> void:
    print("Game:: _init")
    
func _enter_tree() -> void:
    print("Game:: _enter_tree")

func _ready() -> void:
    print("Game:: _ready")
    START_OF_SCREEN_X = get_viewport_rect().position.x
    END_OF_SCREEN_X = get_viewport_rect().end.x
    
    # Stop the timer initially - we'll spawn manually
    spawn_timer.stop()
    spawn_gem()
    
func spawn_gem() -> void:
    # Only spawn if no gem is currently active and game is running
    if current_gem != null or not game_active:
        return
        
    var new_gem: Gem = GEM.instantiate()
    var x_pos: float = randf_range(
        START_OF_SCREEN_X + MARGIN,
        END_OF_SCREEN_X - MARGIN
    )
    new_gem.position = Vector2(x_pos, -MARGIN)
    new_gem.gem_off_screen.connect(_on_gem_off_screen)
    
    # Store reference to current gem
    current_gem = new_gem
    add_child(new_gem)
    print("Spawned new gem at position: ", x_pos)

func stop_all() -> void:
    game_active = false
    sound.stream = EXPLODE
    sound.play()
    spawn_timer.stop()
    paddle.set_process(false)
    
    # Stop current gem if it exists
    if current_gem != null and is_instance_valid(current_gem):
        current_gem.set_process(false)

func _process(delta: float) -> void:
    pass

func _on_gem_off_screen() -> void:
    print("Game:: _on_gem_off_screen - Gem missed, continuing game")
    current_gem = null  # Clear reference
    
    # Spawn next gem after a short delay (no game over)
    await get_tree().create_timer(0.5).timeout
    spawn_gem()
    
func _on_paddle_area_entered(area: Area2D) -> void:
    # Check if the caught area is our current gem
    if area == current_gem:
        _score += 1
        score_label.text = str("SCORE : ", _score)
        print("Gem caught! Score: ", _score)
        
        # Play score sound
        if not score_sound.playing:
            score_sound.position = area.position
            score_sound.play()
        
        # Clear current gem reference
        current_gem = null
        
        # Spawn next gem after a short delay
        await get_tree().create_timer(0.5).timeout
        spawn_gem()


func _on_logout_button_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")
