extends Node3D
# Level 2 - Coin Collection + Static Enemy Hazards
@export var coin_scene: PackedScene
@export var enemy_scene: PackedScene
@export var player: Player
@export var coinTimer: Timer
@export var scoreLabel: Label
@export var level3_transition: SceneTransition2
@export var retryRectangle: ColorRect
@onready var logout_button: Button = $UI/Retry/Label/LogoutButton
@onready var retry_button: Button = $UI/Retry/Label/RetryButton

# Game settings
const SPAWN_INTERVAL = 10.0
const COINS_TO_NEXT_LEVEL = 10
const NUM_ENEMIES = 10
const COIN_HEIGHT_OFFSET = 0.5
const ENEMY_HEIGHT_OFFSET = -0.5
const GAME_OVER_DELAY = 0.75
const MIN_PLAYER_DISTANCE = 2.0
const EMERGENCY_PLAYER_MOVE_DISTANCE = 2.5
const BOX_LINE_BUFFER = 1.0
const BOX_LINE_WOBBLE = 0.3
const MAX_SPAWN_ATTEMPTS = 15
const COLLECTION_DELAY = 0.3  # Time to wait after collection before spawning new coin
const ROTATION_SPEED = 3.0  # Speed of player rotation towards coin

# Game state variables
var current_coin: Node3D = null
var coins_collected = 0
var game_active = true
var is_transitioning = false
var enemies: Array[CharacterBody3D] = []
var occupied_positions: Array[Vector3] = []
var current_box_line_z = GameManager.MIN_Z + 0.5

func _ready() -> void:
    randomize()
    setup_level2()
    retryRectangle.hide()
    
    # IMPROVED: Restore player position and prepare for level transition
    restore_player_position_improved()
    
    # Connect signals - FIXED: Use signal-based coin collection
    SignalBus.player_hit.connect(_on_player_hit.bind())
    SignalBus.coin_collected.connect(_on_coin_collected_signal.bind())
    logout_button.pressed.connect(_on_logout_button_pressed)
    retry_button.pressed.connect(_on_retry_button_pressed)
    
    # Setup coin timer
    coinTimer.wait_time = SPAWN_INTERVAL
    coinTimer.timeout.connect(_on_coin_timer_timeout)
    
    # IMPROVED INITIALIZATION SEQUENCE
    await initialize_level_sequence()

func setup_level2():
    """Initialize Level 2 specific settings"""
    game_active = true
    coins_collected = 0
    is_transitioning = false
    enemies.clear()
    occupied_positions.clear()

func restore_player_position_improved():
    """IMPROVED: Restore player position without causing snapping"""
    if GameManager.has_stored_position and player and is_instance_valid(player):
        var stored_pos = GameManager.get_stored_player_position()
        stored_pos = GameManager.clamp_position_to_bounds(stored_pos)
        
        # Set player position and prepare for transition
        player.global_position = stored_pos
        player.preserve_current_position = true  # NEW: Tell player to preserve position
        
        print("Player position restored to: ", stored_pos)
        GameManager.clear_stored_position()
        
        # Prepare player for level transition
        if player.has_method("prepare_for_level_transition"):
            player.prepare_for_level_transition()
    else:
        print("No stored position, using default safe spawn")
        if player and is_instance_valid(player):
            var safe_default = get_safe_default_position()
            player.global_position = safe_default
            if player.has_method("prepare_for_level_transition"):
                player.prepare_for_level_transition()

func initialize_level_sequence():
    """IMPROVED: Initialize level with proper sequencing"""
    print("=== INITIALIZING LEVEL 2 SEQUENCE ===")
    
    # Step 1: Wait for player to be ready
    await get_tree().process_frame
    
    # Step 2: Set initial box line position based on player
    set_initial_box_line_position()
    
    # Step 3: Spawn enemies with safety checks
    spawn_static_enemies()
    await get_tree().process_frame
    
    # Step 4: Wait a moment for everything to settle
    await get_tree().create_timer(0.5).timeout
    
    # Step 5: Complete player level transition
    if player and player.has_method("complete_level_transition"):
        player.complete_level_transition()
    
    # Step 6: Wait for player calibration to complete
    await get_tree().create_timer(2.0).timeout
    
    # Step 7: Spawn first coin and start game
    spawn_coin()
    coinTimer.start()
    update_score_display()
    
    print("=== LEVEL 2 INITIALIZATION COMPLETE ===")

func ensure_safe_player_position(proposed_pos: Vector3) -> Vector3:
    """Ensure player position won't conflict with enemy spawning zones"""
    var predicted_box_line_z = predict_box_line_position(proposed_pos)
    
    if abs(proposed_pos.z - predicted_box_line_z) < MIN_PLAYER_DISTANCE:
        print("Player position conflicts with enemy spawn zone, adjusting...")
        return find_safe_player_position(proposed_pos)
    
    return proposed_pos

func predict_box_line_position(player_pos: Vector3) -> float:
    """Predict where the box line will be placed given a player position"""
    if player_pos.z < (GameManager.MIN_Z + GameManager.MAX_Z) / 2:
        return GameManager.MAX_Z - BOX_LINE_BUFFER
    else:
        return GameManager.MIN_Z + BOX_LINE_BUFFER

func find_safe_player_position(original_pos: Vector3) -> Vector3:
    """Find a safe position for the player that won't conflict with enemies"""
    var safe_positions = [
        Vector3(GameManager.MIN_X + 0.5, original_pos.y, GameManager.MIN_Z + 0.5),
        Vector3(GameManager.MAX_X - 0.5, original_pos.y, GameManager.MIN_Z + 0.5),
        Vector3(GameManager.MIN_X + 0.5, original_pos.y, GameManager.MAX_Z - 0.5),
        Vector3(GameManager.MAX_X - 0.5, original_pos.y, GameManager.MAX_Z - 0.5),
        Vector3(original_pos.x, original_pos.y, GameManager.MIN_Z + 0.5),
        Vector3(original_pos.x, original_pos.y, GameManager.MAX_Z - 0.5),
        Vector3(GameManager.MIN_X + 0.5, original_pos.y, original_pos.z),
        Vector3(GameManager.MAX_X - 0.5, original_pos.y, original_pos.z),
    ]
    
    for safe_pos in safe_positions:
        var predicted_line = predict_box_line_position(safe_pos)
        if abs(safe_pos.z - predicted_line) >= MIN_PLAYER_DISTANCE:
            print("Found safe position: ", safe_pos)
            return safe_pos
    
    print("Using emergency fallback position")
    return Vector3(GameManager.MIN_X + 0.5, original_pos.y, GameManager.MIN_Z + 0.5)

func get_safe_default_position() -> Vector3:
    """Get a guaranteed safe default position"""
    return Vector3(0, GameManager.FLOOR_Y, GameManager.MIN_Z + 0.5)

func set_initial_box_line_position():
    """IMPROVED: Set initial box line position without moving player"""
    if not player or not is_instance_valid(player):
        current_box_line_z = (GameManager.MIN_Z + GameManager.MAX_Z) / 2
        return
    
    var player_pos = player.global_position
    var safe_distance = MIN_PLAYER_DISTANCE
    
    print("Setting box line with player at: ", player_pos)
    
    # Strategy: Always place enemies on opposite side from player
    if player_pos.z < (GameManager.MIN_Z + GameManager.MAX_Z) / 2:
        # Player in lower half, enemies in upper half
        current_box_line_z = GameManager.MAX_Z - BOX_LINE_BUFFER
    else:
        # Player in upper half, enemies in lower half
        current_box_line_z = GameManager.MIN_Z + BOX_LINE_BUFFER
    
    # Ensure minimum distance
    var distance_to_player = abs(current_box_line_z - player_pos.z)
    if distance_to_player < safe_distance:
        print("Adjusting box line for minimum distance...")
        if current_box_line_z > player_pos.z:
            current_box_line_z = player_pos.z + safe_distance + 0.5
        else:
            current_box_line_z = player_pos.z - safe_distance - 0.5
        
        # Clamp to bounds
        current_box_line_z = clamp(current_box_line_z, GameManager.MIN_Z + 0.5, GameManager.MAX_Z - 0.5)
    
    print("Box line positioned at Z: ", current_box_line_z, " (distance from player: ", abs(current_box_line_z - player_pos.z), ")")

func spawn_static_enemies():
    """IMPROVED: Spawn enemies with better positioning"""
    if not enemy_scene:
        push_error("Enemy scene not assigned!")
        return
    
    cleanup_enemies()
    var spacing = (GameManager.MAX_X - GameManager.MIN_X) / float(NUM_ENEMIES - 1)
    var player_pos = player.global_position if player and is_instance_valid(player) else Vector3.ZERO
    
    print("Spawning ", NUM_ENEMIES, " enemies at box line Z: ", current_box_line_z)
    
    for i in range(NUM_ENEMIES):
        var enemy = enemy_scene.instantiate()
        add_child(enemy)
        
        var x_pos = GameManager.MIN_X + i * spacing
        var z_offset = randf_range(-BOX_LINE_WOBBLE, BOX_LINE_WOBBLE)
        var pos = Vector3(x_pos, GameManager.FLOOR_Y + ENEMY_HEIGHT_OFFSET, current_box_line_z + z_offset)
        
        # Final safety check
        var distance_to_player = pos.distance_to(player_pos)
        if distance_to_player < MIN_PLAYER_DISTANCE:
            print("WARNING: Enemy ", i, " too close to player, adjusting...")
            if pos.z < player_pos.z:
                pos.z = player_pos.z - MIN_PLAYER_DISTANCE - 0.3
            else:
                pos.z = player_pos.z + MIN_PLAYER_DISTANCE + 0.3
            pos.z = clamp(pos.z, GameManager.MIN_Z + 0.5, GameManager.MAX_Z - 0.5)
        
        enemy.global_position = pos
        enemy.rotation_degrees.y = randf_range(-15, 15)
        
        # Initialize enemy
        if enemy.has_method("initialize_as_static_hazard"):
            enemy.initialize_as_static_hazard(pos)
        elif enemy.has_property("velocity"):
            enemy.velocity = Vector3.ZERO
        
        setup_enemy_collision_detection(enemy)
        enemies.append(enemy)
        occupied_positions.append(pos)
    
    print("Successfully spawned ", NUM_ENEMIES, " enemies")
    verify_safe_spawning()

func verify_safe_spawning():
    """Verify that all enemies are safely positioned away from player"""
    if not player or not is_instance_valid(player):
        return
    
    var player_pos = player.global_position
    var unsafe_enemies = []
    
    for i in range(enemies.size()):
        var enemy = enemies[i]
        if is_instance_valid(enemy):
            var distance = enemy.global_position.distance_to(player_pos)
            if distance < MIN_PLAYER_DISTANCE:
                unsafe_enemies.append(i)
                print("DANGER: Enemy ", i, " is only ", distance, " away from player!")
    
    if unsafe_enemies.size() > 0:
        print("CRITICAL: ", unsafe_enemies.size(), " enemies are too close to player!")
        emergency_player_repositioning()
    else:
        print("Safe spawning verified - all enemies are properly positioned")

func emergency_player_repositioning():
    """Emergency function to move player to absolute safety"""
    if not player or not is_instance_valid(player):
        return
    
    print("EMERGENCY: Repositioning player for safety")
    
    var corners = [
        Vector3(GameManager.MIN_X + 0.3, GameManager.FLOOR_Y, GameManager.MIN_Z + 0.3),
        Vector3(GameManager.MAX_X - 0.3, GameManager.FLOOR_Y, GameManager.MIN_Z + 0.3),
        Vector3(GameManager.MIN_X + 0.3, GameManager.FLOOR_Y, GameManager.MAX_Z - 0.3),
        Vector3(GameManager.MAX_X - 0.3, GameManager.FLOOR_Y, GameManager.MAX_Z - 0.3)
    ]
    
    var safest_corner = corners[0]
    var max_min_distance = 0.0
    
    for corner in corners:
        var min_distance_to_enemies = INF
        for enemy in enemies:
            if is_instance_valid(enemy):
                var dist = corner.distance_to(enemy.global_position)
                min_distance_to_enemies = min(min_distance_to_enemies, dist)
        
        if min_distance_to_enemies > max_min_distance:
            max_min_distance = min_distance_to_enemies
            safest_corner = corner
    
    player.global_position = safest_corner
    print("Player moved to safest corner: ", safest_corner, " (min distance to enemies: ", max_min_distance, ")")

func cleanup_enemies():
    """Clean up all existing enemies"""
    for enemy in enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    enemies.clear()
    occupied_positions.clear()

func setup_enemy_collision_detection(enemy: CharacterBody3D):
    """Setup collision detection for enemy hazards"""
    if not enemy or not is_instance_valid(enemy):
        return
    
    var detection_area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    
    var enemy_collision = enemy.find_child("CollisionShape3D")
    if enemy_collision and enemy_collision.shape is BoxShape3D:
        var enemy_box = enemy_collision.shape as BoxShape3D
        box_shape.size = enemy_box.size * 1.1
    else:
        box_shape.size = Vector3(1, 2, 1)
    
    collision_shape.shape = box_shape
    detection_area.add_child(collision_shape)
    enemy.add_child(detection_area)
    
    detection_area.set_collision_layer_value(1, false)
    detection_area.set_collision_mask_value(1, true)
    detection_area.body_entered.connect(_on_enemy_touched.bind(enemy))

func spawn_coin():
    """IMPROVED: Spawn coin with better positioning - FIXED: No direct signal connection"""
    if not game_active or is_transitioning:
        return
    
    debug_coin_spawning()
    
    # Clean up any stray coins (but let collected coins finish their effects)
    cleanup_stray_coins()
    
    # Reposition enemies for subsequent coins (not the first one)
    if coins_collected > 0:
        reposition_enemy_line()
        spawn_static_enemies()
        await get_tree().process_frame
    
    var coin_pos = calculate_coin_position()
    
    if not coin_scene:
        push_error("Coin scene not assigned!")
        return
        
    current_coin = coin_scene.instantiate()
    add_child(current_coin)
    current_coin.add_to_group("coins")
    current_coin.global_position = coin_pos
    
    # Rotate player towards the new coin
    rotate_player_to_coin(coin_pos)
    
    # FIXED: Don't connect directly to coin's body_entered signal
    # The coin will handle its own collection and emit SignalBus.coin_collected
    
    print("Coin spawned at: ", coin_pos)

func rotate_player_to_coin(coin_position: Vector3):
    """Smoothly rotate the player to face the coin"""
    if not player or not is_instance_valid(player):
        return
    
    # Calculate direction from player to coin (only on XZ plane)
    var player_pos = player.global_position
    var direction = Vector3(coin_position.x - player_pos.x, 0, coin_position.z - player_pos.z)
    
    # Don't rotate if the coin is too close or direction is zero
    if direction.length() < 0.1:
        return
    
    direction = direction.normalized()
    
    # Calculate target rotation
    var target_rotation = atan2(direction.x, direction.z)
    
    # Create tween for smooth rotation
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    
    # Get current Y rotation
    var current_rotation = player.rotation.y
    
    # Handle angle wrapping for shortest rotation path
    var angle_diff = target_rotation - current_rotation
    if angle_diff > PI:
        angle_diff -= 2 * PI
    elif angle_diff < -PI:
        angle_diff += 2 * PI
    
    # Smooth rotation to target
    var rotation_duration = abs(angle_diff) / ROTATION_SPEED
    rotation_duration = clamp(rotation_duration, 0.2, 1.0)  # Min 0.2s, max 1.0s
    
    tween.tween_method(
        func(angle): player.rotation.y = angle,
        current_rotation,
        current_rotation + angle_diff,
        rotation_duration
    )
    
    print("Rotating player to face coin at: ", coin_position)

func cleanup_stray_coins():
    """Remove any stray coins that aren't currently being collected"""
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if coin != current_coin and is_instance_valid(coin):
            # Check if the coin is currently being collected
            if not coin.collected:
                coin.queue_free()

func remove_current_coin():
    """Remove the current coin when timer expires"""
    if current_coin and is_instance_valid(current_coin):
        if not current_coin.collected:  # Only remove if not being collected
            current_coin.queue_free()
            print("Removed uncollected coin due to timeout")
        current_coin = null

func reposition_enemy_line():
    """Reposition the enemy line for subsequent coin spawns"""
    if not player or not is_instance_valid(player):
        return
    
    var max_attempts = 10
    var attempt = 0
    var safe_distance = MIN_PLAYER_DISTANCE
    
    while attempt < max_attempts:
        var proposed_z = randf_range(GameManager.MIN_Z + 1.0, GameManager.MAX_Z - 1.0)
        if abs(proposed_z - player.global_position.z) >= safe_distance:
            current_box_line_z = proposed_z
            break
        attempt += 1
        
    if attempt >= max_attempts:
        current_box_line_z = (GameManager.MIN_Z + GameManager.MAX_Z) / 2

func calculate_coin_position() -> Vector3:
    """Calculate optimal coin position relative to player and enemies"""
    if not player or not is_instance_valid(player):
        return Vector3(0, GameManager.FLOOR_Y + COIN_HEIGHT_OFFSET, 0)
    
    var player_z = player.global_position.z
    var coin_z: float
    
    # Position coin on opposite side of box line from player
    if player_z < current_box_line_z:
        coin_z = GameManager.MAX_Z - 0.5
    else:
        coin_z = GameManager.MIN_Z + 0.5
    
    var coin_x = randf_range(GameManager.MIN_X, GameManager.MAX_X)
    return Vector3(coin_x, GameManager.FLOOR_Y + COIN_HEIGHT_OFFSET, coin_z)

func _on_coin_timer_timeout() -> void:
    """Handle coin timer timeout - remove old coin and spawn new one"""
    if not game_active or is_transitioning:
        return
        
    print("Time's up! Removing old coin and spawning new one...")
    
    # Remove the current coin first
    remove_current_coin()
    
    # Small delay to ensure cleanup, then spawn new coin
    await get_tree().create_timer(0.1).timeout
    
    if game_active and not is_transitioning:  # Double check we're still active
        spawn_coin()

func _on_coin_collected_signal():
    """FIXED: Handle coin collection via signal (allows coin to play its effect first)"""
    if not game_active or is_transitioning:
        return
        
    coins_collected += 1
    print("Coin collected! Total: ", coins_collected)
    
    Scoreboard.add_score()
    update_score_display()
    
    if coins_collected >= COINS_TO_NEXT_LEVEL:
        complete_level()
    else:
        # Wait a bit for the coin collection effect to play, then spawn new coin
        await get_tree().create_timer(COLLECTION_DELAY).timeout
        if game_active and not is_transitioning:  # Double check we're still in game
            spawn_coin()
            coinTimer.stop()
            coinTimer.start()

func _on_enemy_touched(enemy: CharacterBody3D, body):
    """Handle player touching an enemy"""
    if not game_active or is_transitioning:
        return
    if body == player or body.is_in_group("player"):
        print("Player touched enemy - Game Over")
        game_over()

func game_over():
    """Handle game over state"""
    game_active = false
    is_transitioning = true
    coinTimer.stop()
    SignalBus.player_hit.emit()

func complete_level():
    """Handle level completion"""
    if is_transitioning:
        return
        
    print("Level 2 completed! Moving to Level 3...")
    is_transitioning = true
    game_active = false
    coinTimer.stop()
    
    # Store player position for next level
    if player and is_instance_valid(player):
        GameManager.store_player_position(player.global_position)
    
    Scoreboard.record_score()
    
    # Small delay to let final coin effect finish
    await get_tree().create_timer(COLLECTION_DELAY).timeout
    
    # Transition to level 3
    if level3_transition and is_instance_valid(level3_transition):
        level3_transition.transition()
    else:
        get_tree().change_scene_to_file("res://Games/Jumpify/levels/level3.tscn")

func update_score_display():
    """Update the score display UI"""
    if scoreLabel and is_instance_valid(scoreLabel):
        scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)

func _on_player_hit() -> void:
    """Handle player hit signal"""
    if is_transitioning:
        return
        
    game_active = false
    is_transitioning = true
    coinTimer.stop()
    
    Scoreboard.record_score()
    await get_tree().create_timer(GAME_OVER_DELAY).timeout
    
    if is_instance_valid(retryRectangle):
        retryRectangle.show()

func _unhandled_input(event: InputEvent) -> void:
    """Handle retry input"""
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        restart_level()

func restart_level():
    """Restart the current level"""
    cleanup_before_restart()
    Scoreboard.reset_score()
    get_tree().reload_current_scene()

func cleanup_before_restart():
    """Clean up before restarting"""
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
    
    cleanup_enemies()
    GameManager.clear_stored_position()

func cleanup_all_coins():
    """Force cleanup of all coins"""
    var existing_coins = get_tree().get_nodes_in_group("coins")
    for coin in existing_coins:
        if is_instance_valid(coin):
            coin.queue_free()

func _on_logout_button_pressed() -> void:
    """Handle logout button press"""
    cleanup_before_restart()
    get_tree().change_scene_to_file("res://Main_screen/Scenes/select_game.tscn")

func _on_retry_button_pressed() -> void:
    """Handle retry button press"""
    restart_level()

# Helper functions for external access
func get_coins_collected() -> int:
    return coins_collected

func get_coins_remaining() -> int:
    return COINS_TO_NEXT_LEVEL - coins_collected

func is_game_active() -> bool:
    return game_active and not is_transitioning

func get_active_enemies() -> Array[CharacterBody3D]:
    return enemies.duplicate()

func debug_coin_spawning():
    """Debug information for coin spawning"""
    print("=== COIN SPAWN DEBUG ===")
    print("Coins collected: ", coins_collected)
    print("Player position: ", player.global_position if player else "No player")
    print("Box line Z: ", current_box_line_z)
    print("Active enemies: ", enemies.size())
    if current_coin and is_instance_valid(current_coin):
        print("Current coin at: ", current_coin.global_position)
    print("========================")

func _exit_tree():
    """Final cleanup when exiting the scene"""
    if coinTimer and coinTimer.timeout.is_connected(_on_coin_timer_timeout):
        coinTimer.timeout.disconnect(_on_coin_timer_timeout)
    
    if SignalBus.coin_collected.is_connected(_on_coin_collected_signal):
        SignalBus.coin_collected.disconnect(_on_coin_collected_signal)
    
    cleanup_all_coins()
    cleanup_enemies()
