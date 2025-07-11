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

# Spawn boundaries
const FLOOR_Y = -0.328
const MIN_X = -2.321
const MAX_X = 2.059
const MIN_Z = -1.179
const MAX_Z = 3.407

# Game settings
const SPAWN_INTERVAL = 10.0
const COINS_TO_NEXT_LEVEL = 10
const NUM_ENEMIES = 10

# Game state variables
var current_coin: Node3D = null
var coins_collected = 0
var game_active = true
var enemies: Array[CharacterBody3D] = []
var occupied_positions: Array[Vector3] = []
var current_box_line_z = MIN_Z + 0.5
var coin_z_offset = MAX_Z - 0.5

func _ready() -> void:
    randomize()
    setup_level2()
    retryRectangle.hide()
    SignalBus.player_hit.connect(_on_player_hit.bind())
    logout_button.pressed.connect(_on_logout_button_pressed)
    retry_button.pressed.connect(_on_retry_button_pressed)

    coinTimer.wait_time = SPAWN_INTERVAL
    coinTimer.timeout.connect(_on_coin_timer_timeout)

    # Set initial box line position before spawning enemies
    set_initial_box_line_position()
    
    # Spawn enemies first, then coin
    spawn_static_enemies()
    await get_tree().process_frame
    spawn_coin()
    
    # Start the timer for subsequent coins
    coinTimer.start()
    update_score_display()

func setup_level2():
    game_active = true
    coins_collected = 0
    enemies.clear()
    occupied_positions.clear()

func set_initial_box_line_position():
    # Set the box line position away from the player at start
    var player_pos = player.global_position
    var safe_distance = 1.5
    
    # Choose a position that's far enough from the player
    if player_pos.z < (MIN_Z + MAX_Z) / 2:
        # Player is in the lower half, put boxes in upper half
        current_box_line_z = MAX_Z - 1.0
    else:
        # Player is in the upper half, put boxes in lower half
        current_box_line_z = MIN_Z + 1.0
    
    # Make sure it's still within bounds and safe distance
    current_box_line_z = clamp(current_box_line_z, MIN_Z + 0.5, MAX_Z - 0.5)
    
    # Double-check distance from player
    if abs(current_box_line_z - player_pos.z) < safe_distance:
        # If still too close, put it at the opposite end
        if player_pos.z < (MIN_Z + MAX_Z) / 2:
            current_box_line_z = MAX_Z - 0.5
        else:
            current_box_line_z = MIN_Z + 0.5

func spawn_static_enemies():
    # Clear previous enemies
    for enemy in enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    enemies.clear()
    occupied_positions.clear()

    var spacing = (MAX_X - MIN_X) / float(NUM_ENEMIES - 1)
    var player_pos = player.global_position

    var tries = 0
    var max_tries = 15
    var min_player_box_distance = 1.5

    while tries < max_tries:
        var temp_enemies: Array[CharacterBody3D] = []
        var temp_positions: Array[Vector3] = []
        var safe = true

        for i in range(NUM_ENEMIES):
            var x_pos = MIN_X + i * spacing
            var z_offset = randf_range(-0.3, 0.3)  # Adds wobble to line
            var box_pos = Vector3(x_pos, FLOOR_Y - 0.5, current_box_line_z + z_offset)

            # Check distance from player
            if box_pos.distance_to(player_pos) < min_player_box_distance:
                safe = false
                break

            temp_positions.append(box_pos)

        if safe:
            # All box positions are safe, now instantiate
            for i in range(NUM_ENEMIES):
                var enemy = enemy_scene.instantiate()
                add_child(enemy)

                var pos = temp_positions[i]
                enemy.global_position = pos

                # Add rotation randomness
                enemy.rotation_degrees.y = randf_range(-15, 15)

                # Optional: call initializer
                if enemy.has_method("initialize_as_static_hazard"):
                    enemy.initialize_as_static_hazard(pos)
                else:
                    enemy.velocity = Vector3.ZERO

                setup_enemy_collision_detection(enemy)
                enemies.append(enemy)
                occupied_positions.append(pos)

            return  # Done spawning
        tries += 1

    # Fallback if no safe layout found
    print("Warning: fallback enemy layout used after ", max_tries, " attempts")

func setup_enemy_collision_detection(enemy: CharacterBody3D):
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
    if not game_active:
        return

    debug_coin_spawning()

    if current_coin != null and is_instance_valid(current_coin):
        current_coin.queue_free()
        current_coin = null

    # Only reposition enemies when spawning a new coin (not the first one)
    if coins_collected > 0:
        # Safe hazard line positioning (avoid player)
        var max_attempts = 10
        var attempt = 0
        var safe_distance = 1.5
        while attempt < max_attempts:
            var proposed_z = randf_range(MIN_Z + 1.0, MAX_Z - 1.0)
            if abs(proposed_z - player.global_position.z) >= safe_distance:
                current_box_line_z = proposed_z
                break
            attempt += 1
        if attempt >= max_attempts:
            current_box_line_z = (MIN_Z + MAX_Z) / 2

        spawn_static_enemies()

    # Spawn coin on the opposite side of the boxes from the player
    var player_z = player.global_position.z
    var coin_z: float
    
    # If player is closer to the box line, put coin on far side
    # If player is farther from box line, put coin on near side
    if player_z < current_box_line_z:
        # Player is below the box line, put coin above it
        coin_z = MAX_Z - 0.5
    else:
        # Player is above the box line, put coin below it
        coin_z = MIN_Z + 0.5
    
    var coin_x = randf_range(MIN_X, MAX_X)

    if coin_scene:
        current_coin = coin_scene.instantiate()
        add_child(current_coin)

        current_coin.global_position = Vector3(coin_x, FLOOR_Y + 0.5, coin_z)

        if current_coin.has_signal("body_entered"):
            current_coin.body_entered.connect(_on_coin_collected)
        
        print("Coin spawned at: ", current_coin.global_position)
        print("Player at: ", player.global_position)
        print("Box line at Z: ", current_box_line_z)

func _on_coin_timer_timeout() -> void:
    if not game_active:
        return
    spawn_coin()

func _on_coin_collected(body):
    if not game_active:
        return
    if body == player or body.is_in_group("player"):
        collect_coin()

func collect_coin():
    if not game_active:
        return
    coins_collected += 1
    Scoreboard.add_score()
    update_score_display()

    if coins_collected >= COINS_TO_NEXT_LEVEL:
        complete_level()
    else:
        spawn_coin()
        coinTimer.stop()
        coinTimer.start()

func _on_enemy_touched(enemy: CharacterBody3D, body):
    if not game_active:
        return
    if body == player or body.is_in_group("player"):
        game_over()

func game_over():
    game_active = false
    coinTimer.stop()
    SignalBus.player_hit.emit()

func complete_level():
    print("Level 2 completed!")
    game_active = false
    coinTimer.stop()
    Scoreboard.record_score()
    if level3_transition:
        level3_transition.transition()
    else:
        get_tree().change_scene_to_file("res://Games/Jumpify/levels/level3.tscn")

func update_score_display():
    if scoreLabel:
        scoreLabel.text = "Coins: " + str(coins_collected) + "/" + str(COINS_TO_NEXT_LEVEL)

func _on_player_hit() -> void:
    game_active = false
    coinTimer.stop()
    Scoreboard.record_score()
    await get_tree().create_timer(0.75).timeout
    retryRectangle.show()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") and retryRectangle.is_visible():
        get_tree().reload_current_scene()
        Scoreboard.reset_score()

func get_coins_collected() -> int:
    return coins_collected

func get_coins_remaining() -> int:
    return COINS_TO_NEXT_LEVEL - coins_collected

func is_game_active() -> bool:
    return game_active

func get_active_enemies() -> Array[CharacterBody3D]:
    return enemies.duplicate()

func debug_coin_spawning():
    print("=== COIN SPAWN DEBUG ===")
    print("Coins collected: ", coins_collected)
    print("Occupied positions: ", occupied_positions.size())
    for i in range(occupied_positions.size()):
        print("Enemy ", i, " at: ", occupied_positions[i])
    if current_coin:
        print("Current coin at: ", current_coin.global_position)
    print("====")
    
    


func _on_logout_button_pressed() -> void:
    get_tree().change_scene_to_file("res://Main_screen/select_game.tscn")


func _on_retry_button_pressed() -> void:
    get_tree().reload_current_scene()
