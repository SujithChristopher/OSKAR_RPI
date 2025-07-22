#extends Node3D
#
## Level 1 - Coin Collection Game
#@export var coin_scene: PackedScene
#@export var player: Player
#@export var coinTimer: Timer
#@export var scoreLabel: Label
#@export var level2_transition: SceneTransition1 # Transition to level 2
#@export var retryRectangle: ColorRect
#
#
## Coin spawning boundaries
#const FLOOR_Y = -0.328
#const MIN_X = -2.321
#const MAX_X = 2.059
#const MIN_Z = -1.179
#const MAX_Z = 3.407
#
## Game settings
#const SPAWN_INTERVAL = 10.0  # seconds
#const COINS_TO_NEXT_LEVEL = 5
#
## Game state variables
#var current_coin: Node3D = null
#var coins_collected = 0
#var game_active = true
#
#func _ready() -> void:
    #setup_level1()
    #retryRectangle.hide()
    #
    ## Connect signals
    #SignalBus.player_hit.connect(_on_player_hit.bind())
    #
    ## Setup coin timer
    #coinTimer.wait_time = SPAWN_INTERVAL
    #coinTimer.timeout.connect(_on_coin_timer_timeout)
    #coinTimer.start()
    #
    ## Spawn first coin immediately
    #spawn_coin()
    #
    ## Update UI
    #update_score_display()
#
#func setup_level1():
    ## Any level 1 specific setup
    #game_active = true
    #coins_collected = 0
#
#func spawn_coin():
    #if not game_active:
        #return
        #
    ## Remove existing coin if present
    #if current_coin != null:
        #current_coin.queue_free()
        #current_coin = null
    #
    ## Create new coin instance
    #if coin_scene:
        #current_coin = coin_scene.instantiate()
        #add_child(current_coin)
        #
        ## Generate random position within boundaries
        #var spawn_position = generate_random_position()
        #current_coin.global_position = spawn_position
        #
        ## Connect coin collection signal
        #if current_coin.has_signal("body_entered"):
            #current_coin.body_entered.connect(_on_coin_collected)
        #
        #print("Coin spawned at position: ", spawn_position)
#
#func generate_random_position() -> Vector3:
    #var x = randf_range(MIN_X, MAX_X)
    #var z = randf_range(MIN_Z, MAX_Z)
    #return Vector3(x, FLOOR_Y + 0.5, z)  # Adding 0.5 to Y so coin floats slightly above floor
#
#func _on_coin_timer_timeout() -> void:
    #if not game_active:
        #return
        #
    ## Time's up - spawn new coin in different location
    #print("Time's up! Spawning new coin...")
    #spawn_coin()
#
#func _on_coin_collected(body):
    #if not game_active:
        #return
        #
    ## Check if it's the player
    #if body == player or body.is_in_group("player"):
        #collect_coin()
#
#func collect_coin():
    #if not game_active:
        #return
        #
    #coins_collected += 1
    #print("Coin collected! Total: ", coins_collected)
    #
    ## Add to scoreboard (reusing the existing score system)
    #Scoreboard.add_score()
    #
    ## Update UI
    #update_score_display()
    #
    ## Check if level is completed
    #if coins_collected >= COINS_TO_NEXT_LEVEL:
        #complete_level()
    #else:
        ## Spawn new coin immediately and restart timer
        #spawn_coin()
        #coinTimer.stop()
        #coinTimer.start()
#
#func complete_level():
    #print("Level 1 completed! Moving to Level 2...")
    #game_active = false
    #coinTimer.stop()
    #
    ## Record the score
    #Scoreboard.record_score()
    #
    ## Transition to level 2
    #if level2_transition:
        #level2_transition.transition()
    #else:
        ## Fallback: load level 2 scene directly
        ## Replace "res://level2.tscn" with your actual level 2 scene path
        #get_tree().change_scene_to_file("res://Games/Jumpify/levels/level2.tscn")
#
#func update_score_display():
    #if scoreLabel:
        #scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)
#
#func _on_player_hit() -> void:
    ## Player hit something - game over
    #game_active = false
    #coinTimer.stop()
    #Scoreboard.record_score()
    #await get_tree().create_timer(0.75).timeout
    #retryRectangle.show()
#
#func _unhandled_input(event: InputEvent) -> void:
    #if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        ## Restart level 1
        #get_tree().reload_current_scene()
        #Scoreboard.reset_score()
#
## Helper functions for external access
#func get_coins_collected() -> int:
    #return coins_collected
#
#func get_coins_remaining() -> int:
    #return COINS_TO_NEXT_LEVEL - coins_collected
#
#func is_game_active() -> bool:
    #return game_active
#
#
#func _on_logout_pressed() -> void:
   #get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

extends Node3D

# Level 1 - Coin Collection Game
@export var coin_scene: PackedScene
@export var player: Player
@export var coinTimer: Timer
@export var scoreLabel: Label
@export var level2_transition: SceneTransition1 # Transition to level 2
@export var retryRectangle: ColorRect

# Coin spawning boundaries
const FLOOR_Y = -0.328
const MIN_X = -2.321
const MAX_X = 2.059
const MIN_Z = -1.179
const MAX_Z = 3.407

# Game settings
const SPAWN_INTERVAL = 10.0  # seconds
const COINS_TO_NEXT_LEVEL = 5
const COIN_HEIGHT_OFFSET = 0.5

# Game state variables
var current_coin: Node3D = null
var coins_collected = 0
var game_active = true
var is_transitioning = false

func _ready() -> void:
    setup_level1()
    retryRectangle.hide()
    
    # Connect signals
    SignalBus.player_hit.connect(_on_player_hit.bind())
    
    # Setup coin timer
    coinTimer.wait_time = SPAWN_INTERVAL
    coinTimer.timeout.connect(_on_coin_timer_timeout)
    coinTimer.start()
    
    # Spawn first coin immediately
    spawn_coin()
    
    # Update UI
    update_score_display()

func setup_level1():
    # Level 1 specific setup
    game_active = true
    coins_collected = 0
    is_transitioning = false

func spawn_coin():
    if not game_active or is_transitioning:
        return
        
    # Remove existing coin if present
    if current_coin != null and is_instance_valid(current_coin):
        current_coin.queue_free()
        current_coin = null
    
    # Clean up any stray coins from previous levels
    cleanup_existing_coins()
    
    # Create new coin instance
    if coin_scene:
        current_coin = coin_scene.instantiate()
        add_child(current_coin)
        
        # Add to group for tracking
        current_coin.add_to_group("coins")
        
        # Generate random position within boundaries
        var spawn_position = generate_random_position()
        current_coin.global_position = spawn_position
        
        # Connect coin collection signal with error checking
        if current_coin.has_signal("body_entered"):
            if not current_coin.body_entered.is_connected(_on_coin_collected):
                current_coin.body_entered.connect(_on_coin_collected)
        else:
            print("Warning: Coin scene doesn't have body_entered signal")
        
        print("Coin spawned at position: ", spawn_position)

func cleanup_existing_coins():
    # Remove any existing coins that aren't our current coin
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if coin != current_coin and is_instance_valid(coin):
            coin.queue_free()

func generate_random_position() -> Vector3:
    var x = randf_range(MIN_X, MAX_X)
    var z = randf_range(MIN_Z, MAX_Z)
    return Vector3(x, FLOOR_Y + COIN_HEIGHT_OFFSET, z)

func _on_coin_timer_timeout() -> void:
    if not game_active or is_transitioning:
        return
        
    # Time's up - spawn new coin in different location
    print("Time's up! Spawning new coin...")
    spawn_coin()

func _on_coin_collected(body):
    if not game_active or is_transitioning:
        return
        
    # Check if it's the player
    if body == player or body.is_in_group("player"):
        collect_coin()

func collect_coin():
    if not game_active or is_transitioning:
        return
        
    coins_collected += 1
    print("Coin collected! Total: ", coins_collected)
    
    # Add to scoreboard (reusing the existing score system)
    Scoreboard.add_score()
    
    # Update UI
    update_score_display()
    
    # Check if level is completed
    if coins_collected >= COINS_TO_NEXT_LEVEL:
        complete_level()
    else:
        # Spawn new coin immediately and restart timer
        spawn_coin()
        coinTimer.stop()
        coinTimer.start()

func complete_level():
    if is_transitioning:
        return
        
    print("Level 1 completed! Moving to Level 2...")
    is_transitioning = true
    game_active = false
    
    # Stop timer and disconnect signals
    coinTimer.stop()
    if coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    # Clean up current coin
    if current_coin != null and is_instance_valid(current_coin):
        if current_coin.body_entered.is_connected(_on_coin_collected):
            current_coin.body_entered.disconnect(_on_coin_collected)
        current_coin.queue_free()
        current_coin = null
    
    # Clean up any remaining coins
    cleanup_existing_coins()
    
    # Record the score
    Scoreboard.record_score()
    
    # Small delay to ensure cleanup
    await get_tree().create_timer(0.1).timeout
    
    # Transition to level 2
    if level2_transition and is_instance_valid(level2_transition):
        level2_transition.transition()
    else:
        # Fallback: load level 2 scene directly
        get_tree().change_scene_to_file("res://Games/Jumpify/levels/level2.tscn")

func update_score_display():
    if scoreLabel and is_instance_valid(scoreLabel):
        scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)

func _on_player_hit() -> void:
    if is_transitioning:
        return
        
    # Player hit something - game over
    game_active = false
    coinTimer.stop()
    
    # Disconnect timer signal
    if coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    Scoreboard.record_score()
    await get_tree().create_timer(0.75).timeout
    
    if is_instance_valid(retryRectangle):
        retryRectangle.show()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        # Restart level 1
        cleanup_before_restart()
        get_tree().reload_current_scene()
        Scoreboard.reset_score()

func cleanup_before_restart():
    # Clean up everything before restart
    game_active = false
    is_transitioning = false
    coinTimer.stop()
    
    if current_coin != null and is_instance_valid(current_coin):
        current_coin.queue_free()
        current_coin = null
    
    cleanup_existing_coins()

# Helper functions for external access
func get_coins_collected() -> int:
    return coins_collected

func get_coins_remaining() -> int:
    return COINS_TO_NEXT_LEVEL - coins_collected

func is_game_active() -> bool:
    return game_active and not is_transitioning

func _on_logout_pressed() -> void:
    cleanup_before_restart()
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

# Called when the node is about to be removed from the scene
func _exit_tree():
    # Final cleanup
    if coinTimer and coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    if current_coin != null and is_instance_valid(current_coin):
        if current_coin.body_entered.is_connected(_on_coin_collected):
            current_coin.body_entered.disconnect(_on_coin_collected)
    
    cleanup_existing_coins()
