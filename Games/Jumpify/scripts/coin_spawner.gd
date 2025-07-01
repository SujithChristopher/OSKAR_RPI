extends Node3D

# Preload the coin scene
@export var coin_scene: PackedScene = preload("res://Games/Jumpify/levels/entities/coin.tscn")
@onready var coin_sound: AudioStreamPlayer3D = $CoinSound

# Spawn timer
var spawn_timer: Timer
var current_coin: Node3D = null

# 3D spawn boundaries based on your level measurements
@export var coin_height: float = -0.328
@export var x_min: float = -2.321
@export var x_max: float = 2.059
@export var z_min: float = -1.179
@export var z_max: float = 3.407

func _ready():
    # Create and configure timer
    spawn_timer = Timer.new()
    spawn_timer.wait_time = 10.0  # 10 seconds
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    add_child(spawn_timer)
    
    # Spawn the first coin immediately
    spawn_coin()

func _on_spawn_timer_timeout():
    print("Timer timeout - checking for coin...")
    # Only spawn if there's no current coin
    if current_coin == null:
        print("No coin exists, spawning new one")
        spawn_coin()
    else:
        print("Coin already exists, waiting...")

func spawn_coin():
    # Remove existing coin if any
    if current_coin != null:
        print("Removing existing coin")
        current_coin.queue_free()
        current_coin = null
    
    # Create new coin instance
    current_coin = coin_scene.instantiate()
    
    if current_coin == null:
        print("ERROR: Failed to instantiate coin scene!")
        return
    
    # Add coin to scene FIRST
    var scene_root = get_tree().current_scene
    scene_root.add_child(current_coin)
    
    # Wait one frame for the node to be ready
    await get_tree().process_frame
    
    # Generate random position within 3D spawn area
    var spawn_pos = get_random_spawn_position()
    
    # Set position using transform instead of global_position
    current_coin.transform.origin = spawn_pos
    
    # Force the coin to be visible and enabled
    current_coin.visible = true
    current_coin.process_mode = Node.PROCESS_MODE_INHERIT
    
    # Debug: Print coin's actual properties
    print("Coin spawned at: ", spawn_pos)
    print("Coin visible: ", current_coin.visible)
    print("Coin scale: ", current_coin.scale)
    print("Coin actual position: ", current_coin.transform.origin)
    print("Coin global position: ", current_coin.global_position)
    
    # Connect coin collected signal AFTER adding to scene
    if current_coin.has_signal("collected"):
        current_coin.collected.connect(_on_coin_collected)
        print("Connected collected signal")
    else:
        print("WARNING: Coin doesn't have 'collected' signal!")
    
    # Debug: Create a visible marker at spawn position
    #create_debug_marker(spawn_pos)

# Debug function to create visible markers
#func create_debug_marker(pos: Vector3):
    #var marker = MeshInstance3D.new()
    #var sphere_mesh = SphereMesh.new()
    #sphere_mesh.radius = 0.2
    #sphere_mesh.height = 0.4
    #marker.mesh = sphere_mesh
    #marker.global_position = pos
    #
    ## Make it bright red so it's easy to spot
    #var material = StandardMaterial3D.new()
    #material.albedo_color = Color.RED
    #material.emission_enabled = true
    #material.emission_color = Color.RED
    #marker.material_override = material
    #
    #get_tree().current_scene.add_child(marker)
    
    # Remove marker after 5 seconds
    var timer = Timer.new()
    timer.wait_time = 5.0
    timer.one_shot = true
    add_child(timer)
    timer.start()

func get_random_spawn_position() -> Vector3:
    # TEMPORARY: Use a fixed position for testing (where your manual coin works)
    # You can change this back to random once we fix the visibility issue
    return Vector3(0, -0.328, 0)  # Test with center position first
    
    # Original random code (commented out for now):
    # var random_x = randf_range(x_min, x_max)
    # var random_z = randf_range(z_min, z_max)
    # var spawn_y = coin_height
    # return Vector3(random_x, spawn_y, random_z)

func _on_coin_collected():
    print("Coin collected! Spawning new one...")
    current_coin = null
    # Small delay before spawning new coin to ensure cleanup
    await get_tree().create_timer(0.1).timeout
    spawn_coin()

# Optional: Method to manually spawn coin (for testing)
func force_spawn_coin():
    spawn_coin()

# Optional: Method to set custom spawn boundaries
func set_spawn_boundaries(height: float, x_minimum: float, x_maximum: float, z_minimum: float, z_maximum: float):
    coin_height = height
    x_min = x_minimum
    x_max = x_maximum
    z_min = z_minimum
    z_max = z_maximum
