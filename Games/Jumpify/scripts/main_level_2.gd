extends Node3D

# Level 2 - Coin Collection + Static Enemy Hazards
@export var coin_scene: PackedScene
@export var enemy_scene: PackedScene  # Your existing enemy.tscn
@export var player: Player
@export var coinTimer: Timer
@export var scoreLabel: Label
@export var level3_transition: SceneTransition  # Transition to next level (if exists)
@export var retryRectangle: ColorRect

# Spawn boundaries (same as level 1)
const FLOOR_Y = -0.328
const MIN_X = -2.321
const MAX_X = 2.059
const MIN_Z = -1.179
const MAX_Z = 3.407

# Game settings
const SPAWN_INTERVAL = 8.0  # Slightly faster than level 1
const COINS_TO_NEXT_LEVEL = 1  # More coins required
const NUM_ENEMIES = 6

# Game state variables
var current_coin: Node3D = null
var coins_collected = 0
var game_active = true
var enemies: Array[CharacterBody3D] = []  # Store all spawned enemies
var occupied_positions: Array[Vector3] = []  # Track occupied positions

func _ready() -> void:
    # Seed the random number generator with current time
    randomize()
    
    setup_level2()
    retryRectangle.hide()
    
    # Connect signals
    SignalBus.player_hit.connect(_on_player_hit.bind())
    
    # Setup coin timer
    coinTimer.wait_time = SPAWN_INTERVAL
    coinTimer.timeout.connect(_on_coin_timer_timeout)
    
    # First spawn enemies, then coins
    spawn_static_enemies()
    await get_tree().process_frame  # Wait a frame for enemies to be positioned
    
    coinTimer.start()
    spawn_coin()
    
    # Update UI
    update_score_display()

func setup_level2():
    game_active = true
    coins_collected = 0
    enemies.clear()
    occupied_positions.clear()

func spawn_static_enemies():
    print("Spawning ", NUM_ENEMIES, " static enemies...")
    
    for i in range(NUM_ENEMIES):
        if enemy_scene == null:
            print("ERROR: Enemy scene not assigned!")
            return
        
        var enemy = enemy_scene.instantiate()
        add_child(enemy)
        
        # Generate position that doesn't overlap with other enemies
        var enemy_position = generate_non_overlapping_position(1.2)  # 1.2 meter minimum distance
        
        # Use the enemy's initialize method if available
        if enemy.has_method("initialize_as_static_hazard"):
            enemy.initialize_as_static_hazard(enemy_position)
        else:
            # Fallback positioning
            enemy.global_position = enemy_position
            enemy.velocity = Vector3.ZERO  # Make it static
        
        # Disable the screen exit detection since they're static
        var screen_notifier = enemy.find_child("VisibleOnScreenNotifier3D")
        if screen_notifier:
            screen_notifier.queue_free()
        
        # Connect to player collision detection
        setup_enemy_collision_detection(enemy)
        
        # Store enemy reference and position
        enemies.append(enemy)
        occupied_positions.append(enemy_position)
        
        print("Static enemy ", i + 1, " spawned at: ", enemy_position)

func setup_enemy_collision_detection(enemy: CharacterBody3D):
    # Since your enemy is CharacterBody3D, we need to add collision detection
    # We'll check for collision in _physics_process or add an Area3D child
    
    # Option 1: Add Area3D as child for detection
    var detection_area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    
    # Match the size to the enemy's collision shape
    var enemy_collision = enemy.find_child("CollisionShape3D")
    if enemy_collision and enemy_collision.shape is BoxShape3D:
        var enemy_box = enemy_collision.shape as BoxShape3D
        box_shape.size = enemy_box.size * 1.1  # Slightly larger for better detection
    else:
        box_shape.size = Vector3(1, 2, 1)  # Default size
    
    collision_shape.shape = box_shape
    detection_area.add_child(collision_shape)
    enemy.add_child(detection_area)
    
    # Set up collision layers for detection area
    detection_area.set_collision_layer_value(1, false)
    detection_area.set_collision_mask_value(1, true)  # Detect player
    
    # Connect the body_entered signal
    detection_area.body_entered.connect(_on_enemy_touched.bind(enemy))
    
    print("Collision detection set up for enemy at: ", enemy.global_position)

func generate_non_overlapping_position(min_distance: float) -> Vector3:
    var max_attempts = 50
    var attempts = 0
    
    while attempts < max_attempts:
        randomize()
        var x = randf_range(MIN_X, MAX_X)
        var z = randf_range(MIN_Z, MAX_Z)
        var test_position = Vector3(x, FLOOR_Y - 0.5, z)
        
        # Check if this position is far enough from existing enemies
        var valid_position = true
        for occupied_pos in occupied_positions:
            var distance = test_position.distance_to(occupied_pos)
            if distance < min_distance:
                valid_position = false
                break
        
        if valid_position:
            return test_position
        
        attempts += 1
    
    # Fallback: return a position even if not ideal
    print("Warning: Could not find ideal enemy position after ", max_attempts, " attempts")
    return Vector3(randf_range(MIN_X, MAX_X), FLOOR_Y - 0.5, randf_range(MIN_Z, MAX_Z))

func spawn_coin():
    if not game_active:
        return
    
    debug_coin_spawning()  # Debug info
        
    # Remove existing coin if present
    if current_coin != null and is_instance_valid(current_coin):
        current_coin.queue_free()
        current_coin = null
    
    # Create new coin instance
    if coin_scene:
        current_coin = coin_scene.instantiate()
        add_child(current_coin)
        
        # Generate position that doesn't collide with enemies
        var coin_position = generate_coin_position_avoiding_enemies()
        current_coin.global_position = coin_position
        
        # Connect coin collection signal
        if current_coin.has_signal("body_entered"):
            current_coin.body_entered.connect(_on_coin_collected)
        
        print("Coin spawned at position: ", coin_position)

func generate_coin_position_avoiding_enemies() -> Vector3:
    var max_attempts = 30
    var attempts = 0
    var min_distance_from_enemy = 1.8  # Minimum distance from any enemy
    
    while attempts < max_attempts:
        # Use Time.get_ticks_msec() for better randomization
        randomize()
        var x = randf_range(MIN_X, MAX_X)
        var z = randf_range(MIN_Z, MAX_Z)
        var test_position = Vector3(x, FLOOR_Y + 0.5, z)  # Coin floats above floor
        
        # Check distance from all enemies
        var safe_position = true
        for enemy_pos in occupied_positions:
            # Compare using 2D distance (ignore Y difference)
            var enemy_pos_2d = Vector2(enemy_pos.x, enemy_pos.z)
            var test_pos_2d = Vector2(test_position.x, test_position.z)
            var distance = enemy_pos_2d.distance_to(test_pos_2d)
            
            if distance < min_distance_from_enemy:
                safe_position = false
                break
        
        if safe_position:
            return test_position
        
        attempts += 1
    
    # Better fallback positions - cycle through different safe spots
    var fallback_positions = [
        Vector3(0, FLOOR_Y + 0.5, 0),           # Center
        Vector3(MIN_X + 0.5, FLOOR_Y + 0.5, MIN_Z + 0.5),  # Corner 1
        Vector3(MAX_X - 0.5, FLOOR_Y + 0.5, MIN_Z + 0.5),  # Corner 2
        Vector3(MIN_X + 0.5, FLOOR_Y + 0.5, MAX_Z - 0.5),  # Corner 3
        Vector3(MAX_X - 0.5, FLOOR_Y + 0.5, MAX_Z - 0.5),  # Corner 4
        Vector3(0, FLOOR_Y + 0.5, MAX_Z - 0.5),            # Back center
        Vector3(0, FLOOR_Y + 0.5, MIN_Z + 0.5),            # Front center
    ]
    
    # Use coins_collected to cycle through fallback positions
    var fallback_index = coins_collected % fallback_positions.size()
    print("Warning: Using fallback coin position #", fallback_index)
    return fallback_positions[fallback_index]

func _on_coin_timer_timeout() -> void:
    if not game_active:
        return
        
    print("Time's up! Spawning new coin...")
    spawn_coin()

func _on_coin_collected(body):
    if not game_active:
        return
        
    # Check if it's the player
    if body == player or body.is_in_group("player"):
        collect_coin()

func collect_coin():
    if not game_active:
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
        # Spawn new coin immediately and restart timer
        spawn_coin()
        coinTimer.stop()
        coinTimer.start()

func _on_enemy_touched(enemy: CharacterBody3D, body):
    if not game_active:
        return
    
    # Check if it's the player
    if body == player or body.is_in_group("player"):
        print("Player touched enemy at: ", enemy.global_position, "! Game Over!")
        game_over()

func game_over():
    game_active = false
    coinTimer.stop()
    
    # Trigger the player hit signal for consistency
    SignalBus.player_hit.emit()

func complete_level():
    print("Level 2 completed!")
    game_active = false
    coinTimer.stop()
    
    # Record the score
    Scoreboard.record_score()
    
    # Transition to next level or back to menu
    if level3_transition:
        level3_transition.transition()
    else:
        # Fallback: You can load level 3 or go back to main menu
        print("Level 2 completed! Add your next level transition here.")
        # get_tree().change_scene_to_file("res://main_menu.tscn")  # or level 3

func update_score_display():
    if scoreLabel:
        scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)

func _on_player_hit() -> void:
    # Player hit something or touched an enemy - game over
    game_active = false
    coinTimer.stop()
    Scoreboard.record_score()
    await get_tree().create_timer(0.75).timeout
    retryRectangle.show()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        # Restart level 2
        get_tree().reload_current_scene()
        Scoreboard.reset_score()

# Helper functions
func get_coins_collected() -> int:
    return coins_collected

func get_coins_remaining() -> int:
    return COINS_TO_NEXT_LEVEL - coins_collected

func is_game_active() -> bool:
    return game_active

func get_active_enemies() -> Array[CharacterBody3D]:
    return enemies.duplicate()

# Debug function to help troubleshoot
func debug_coin_spawning():
    print("=== COIN SPAWN DEBUG ===")
    print("Coins collected: ", coins_collected)
    print("Occupied positions: ", occupied_positions.size())
    for i in range(occupied_positions.size()):
        print("Enemy ", i, " at: ", occupied_positions[i])
    if current_coin:
        print("Current coin at: ", current_coin.global_position)
    print("========================")

# Debug function to visualize enemy positions
func debug_print_positions():
    print("=== LEVEL 2 DEBUG INFO ===")
    print("Active enemies: ", enemies.size())
    for i in range(enemies.size()):
        if enemies[i] != null:
            print("Enemy ", i, " at: ", enemies[i].global_position)
    print("Occupied positions: ", occupied_positions.size())
    print("=========================")
