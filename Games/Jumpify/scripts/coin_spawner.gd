extends Node3D

@export var coin_scene: PackedScene = preload("res://Games/Jumpify/levels/entities/coin.tscn")
@onready var coin_sound: AudioStreamPlayer3D = $CoinSound

@export_group("Spawn Settings")
@export var spawn_interval: float = 10.0
@export var spawn_delay: float = 0.1

@export_group("Spawn Boundaries")
@export var coin_height: float = -0.328
@export var x_min: float = -2.321
@export var x_max: float = 2.059
@export var z_min: float = -1.179
@export var z_max: float = 3.407

var spawn_timer: Timer
var current_coin: Node3D = null

func _ready():
    setup_timer()
    spawn_coin()

func setup_timer():
    spawn_timer = Timer.new()
    spawn_timer.wait_time = spawn_interval
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    add_child(spawn_timer)

func _on_spawn_timer_timeout():
    if current_coin == null:
        spawn_coin()

func spawn_coin():
    cleanup_current_coin()
    
    if not coin_scene:
        push_error("Coin scene not assigned!")
        return
    
    current_coin = coin_scene.instantiate()
    if not current_coin:
        push_error("Failed to instantiate coin scene!")
        return
    
    get_tree().current_scene.add_child(current_coin)
    await get_tree().process_frame
    
    # Check if current_coin is still valid after awaiting
    if current_coin and is_instance_valid(current_coin):
        current_coin.global_position = get_random_spawn_position()
        
        if current_coin.has_signal("collected"):
            current_coin.collected.connect(_on_coin_collected)
    else:
        push_error("Current coin became invalid during spawn process!")

func cleanup_current_coin():
    if current_coin and is_instance_valid(current_coin):
        current_coin.queue_free()
        current_coin = null

func get_random_spawn_position() -> Vector3:
    var random_x = randf_range(x_min, x_max)
    var random_z = randf_range(z_min, z_max)
    return Vector3(random_x, coin_height, random_z)

func _on_coin_collected():
    if current_coin and is_instance_valid(current_coin):
        current_coin = null
    await get_tree().create_timer(spawn_delay).timeout
    spawn_coin()

func force_spawn_coin():
    spawn_coin()

func set_spawn_boundaries(height: float, x_minimum: float, x_maximum: float, z_minimum: float, z_maximum: float):
    coin_height = height
    x_min = x_minimum
    x_max = x_maximum
    z_min = z_minimum
    z_max = z_maximum
