extends Node3D

# Level 1 - Coin Collection Game
@export var coin_scene: PackedScene
@export var player: Player
@export var coinTimer: Timer
@export var scoreLabel: Label
@export var level2_transition: SceneTransition1 # Transition to level 2
@export var retryRectangle: ColorRect

# Game settings
const SPAWN_INTERVAL = 10.0  # seconds
const COINS_TO_NEXT_LEVEL = 5
const COIN_HEIGHT_OFFSET = 0.5
const GAME_OVER_DELAY = 0.75
const CLEANUP_DELAY = 0.1
const COLLECTION_DELAY = 0.3  # Time to wait after collection before spawning new coin

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
    SignalBus.coin_collected.connect(_on_coin_collected_signal.bind())
    
    # Setup coin timer
    coinTimer.wait_time = SPAWN_INTERVAL
    coinTimer.timeout.connect(_on_coin_timer_timeout)
    coinTimer.start()
    
    # Spawn first coin immediately
    spawn_coin()
    
    # Update UI
    update_score_display()

func setup_level1():
    """Initialize Level 1 specific settings"""
    game_active = true
    coins_collected = 0
    is_transitioning = false
    
    # Clear any stored position from previous sessions
    GameManager.clear_stored_position()

func spawn_coin():
    """Spawn a new coin at a random valid position"""
    if not game_active or is_transitioning:
        return
    
    # Clean up any stray coins from previous levels (but not current coin if it's being collected)
    cleanup_stray_coins()
    
    # Create new coin instance
    if not coin_scene:
        push_error("Coin scene not assigned!")
        return
        
    var new_coin = coin_scene.instantiate()
    add_child(new_coin)
    
    # Add to group for tracking
    new_coin.add_to_group("coins")
    
    # Generate random position within boundaries
    var spawn_position = generate_random_position()
    new_coin.global_position = spawn_position
    
    # Update current coin reference
    current_coin = new_coin
    
    print("Coin spawned at position: ", spawn_position)

func cleanup_stray_coins():
    """Remove any stray coins that aren't our current coin or being collected"""
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if coin != current_coin and is_instance_valid(coin):
            # Check if the coin is currently being collected (has scaling tween running)
            if not coin.collected:
                coin.queue_free()

func generate_random_position() -> Vector3:
    """Generate a random position within the game boundaries"""
    var x = randf_range(GameManager.MIN_X, GameManager.MAX_X)
    var z = randf_range(GameManager.MIN_Z, GameManager.MAX_Z)
    return Vector3(x, GameManager.FLOOR_Y + COIN_HEIGHT_OFFSET, z)

func _on_coin_timer_timeout() -> void:
    """Handle coin timer timeout - spawn new coin"""
    if not game_active or is_transitioning:
        return
        
    print("Time's up! Spawning new coin...")
    spawn_coin()

func _on_coin_collected_signal():
    """Handle coin collection via signal (allows coin to play its effect first)"""
    if not game_active or is_transitioning:
        return
        
    coins_collected += 1
    print("Coin collected! Total: ", coins_collected)
    
    # Add to scoreboard
    Scoreboard.add_score()
    
    # Update UI
    update_score_display()
    
    # Check if level is completed
    if coins_collected >= COINS_TO_NEXT_LEVEL:
        complete_level()
    else:
        # Wait a bit for the coin collection effect to play, then spawn new coin
        await get_tree().create_timer(COLLECTION_DELAY).timeout
        if game_active and not is_transitioning:  # Double check we're still in game
            spawn_coin()
            coinTimer.stop()
            coinTimer.start()

func complete_level():
    """Handle level completion and transition to level 2"""
    if is_transitioning:
        return
        
    print("Level 1 completed! Moving to Level 2...")
    is_transitioning = true
    game_active = false
    
    # Store player position for Level 2
    if player and is_instance_valid(player):
        GameManager.store_player_position(player.global_position)
    
    # Stop timer and disconnect signals
    coinTimer.stop()
    if coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    # Clean up any remaining coins (but let current one finish its effect)
    cleanup_remaining_coins()
    
    # Record the score
    Scoreboard.record_score()
    
    # Small delay to ensure cleanup and let final coin effect finish
    await get_tree().create_timer(CLEANUP_DELAY + COLLECTION_DELAY).timeout
    
    # Transition to level 2
    if level2_transition and is_instance_valid(level2_transition):
        level2_transition.transition()
    else:
        # Fallback: load level 2 scene directly
        get_tree().change_scene_to_file("res://Games/Jumpify/levels/level2.tscn")

func cleanup_remaining_coins():
    """Clean up remaining coins, but let collected ones finish their effects"""
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if is_instance_valid(coin) and not coin.collected:
            coin.queue_free()

func update_score_display():
    """Update the score display UI"""
    if scoreLabel and is_instance_valid(scoreLabel):
        scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)

func _on_player_hit() -> void:
    """Handle player being hit - game over"""
    if is_transitioning:
        return
        
    print("Player hit - Game Over")
    game_active = false
    coinTimer.stop()
    
    # Disconnect timer signal
    if coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    Scoreboard.record_score()
    await get_tree().create_timer(GAME_OVER_DELAY).timeout
    
    if is_instance_valid(retryRectangle):
        retryRectangle.show()

func _unhandled_input(event: InputEvent) -> void:
    """Handle input for retry"""
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        restart_level()

func restart_level():
    """Restart the current level"""
    cleanup_before_restart()
    Scoreboard.reset_score()
    get_tree().reload_current_scene()

func cleanup_before_restart():
    """Clean up everything before restart"""
    game_active = false
    is_transitioning = false
    coinTimer.stop()
    
    # Disconnect signals
    if coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    if SignalBus.coin_collected.is_connected(_on_coin_collected_signal):
        SignalBus.coin_collected.disconnect(_on_coin_collected_signal)
    
    # Clean up all coins
    cleanup_all_coins()
    current_coin = null
    
    GameManager.clear_stored_position()

func cleanup_all_coins():
    """Force cleanup of all coins"""
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if is_instance_valid(coin):
            coin.queue_free()

func _on_logout_pressed() -> void:
    """Handle logout button press"""
    cleanup_before_restart()
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

# Helper functions for external access
func get_coins_collected() -> int:
    return coins_collected

func get_coins_remaining() -> int:
    return COINS_TO_NEXT_LEVEL - coins_collected

func is_game_active() -> bool:
    return game_active and not is_transitioning

# Called when the node is about to be removed from the scene
func _exit_tree():
    """Final cleanup when exiting the scene"""
    if coinTimer and coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    if SignalBus.coin_collected.is_connected(_on_coin_collected_signal):
        SignalBus.coin_collected.disconnect(_on_coin_collected_signal)
    
    cleanup_all_coins()
