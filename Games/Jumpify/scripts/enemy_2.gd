extends CharacterBody3D

# Static enemy version for Level 2 - acts as hazard boxes
@export_group("Appearance")
@export var min_scale = 0.8
@export var max_scale = 1.5
@export var hazard_color = Color.RED

@export_group("Animation")
@export var collision_shape: CollisionShape3D
@export var animation_player: AnimationPlayer
@export var pulse_speed = 2.0
@export var pulse_intensity = 0.1

@export_group("Sound")
@export var death_sound: AudioStreamPlayer

var is_dead = false
var initial_scale: Vector3
var time_passed = 0.0
var mesh_instance: MeshInstance3D

func _ready():
    # Store initial scale for pulsing
    initial_scale = scale
    
    # Find mesh instance for visual effects
    mesh_instance = find_child("MeshInstance3D")
    if mesh_instance:
        setup_hazard_appearance()

func _physics_process(_delta: float) -> void:
    # Don't move - stay static
    velocity = Vector3.ZERO
    # Still call move_and_slide for physics consistency
    move_and_slide()

func _process(delta):
    if is_dead:
        return
        
    # Add menacing pulse animation
    time_passed += delta
    var pulse = sin(time_passed * pulse_speed) * pulse_intensity
    scale = initial_scale + Vector3(pulse, pulse * 0.5, pulse)  # Less vertical pulse

func initialize_as_static_hazard(start_position: Vector3) -> void:
    # Position the enemy as a static hazard
    global_position = start_position
    velocity = Vector3.ZERO
    
    # Randomize scale to make each hazard unique
    var target_scale = Vector3(
        randf_range(min_scale, max_scale),
        1.0,
        randf_range(min_scale, max_scale)
    )
    scale *= target_scale
    initial_scale = scale
    
    # Random rotation for variety
    rotation.y = randf_range(0, PI * 2)
    
    print("Static hazard initialized at: ", global_position)

func setup_hazard_appearance():
    if not mesh_instance:
        return
    
    # Create menacing hazard material
    var hazard_material = StandardMaterial3D.new()
    hazard_material.albedo_color = hazard_color
    hazard_material.emission_enabled = true
    hazard_material.emission_color = hazard_color * 0.4
    hazard_material.metallic = 0.3
    hazard_material.roughness = 0.7
    
    # Apply pulsing emission
    var emission_strength = 0.4 + (sin(time_passed * pulse_speed * 1.5) * 0.2)
    hazard_material.emission_color = hazard_color * emission_strength
    
    mesh_instance.set_surface_override_material(0, hazard_material)

# Override the original squash method - hazards shouldn't be squashed
func squash() -> void:
    # In Level 2, touching enemies causes game over, not squashing
    print("Hazard touched - this should trigger game over!")
    trigger_death_effect()

func trigger_death_effect():
    if is_dead:
        return
        
    is_dead = true
    
    # Visual feedback - flash and grow
    var tween = create_tween()
    tween.parallel().tween_property(self, "scale", initial_scale * 1.3, 0.1)
    tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.05)
    tween.tween_property(self, "modulate", hazard_color, 0.05)
    
    # Play death sound if available
    if death_sound:
        death_sound.pitch_scale = 1.2  # Higher pitch for danger
        death_sound.play()

func is_alive() -> bool:
    return !is_dead

# Method to change hazard level/appearance
func set_hazard_level(level: int):
    match level:
        1:
            hazard_color = Color.ORANGE
            pulse_speed = 1.5
        2:
            hazard_color = Color.RED
            pulse_speed = 2.0
        3:
            hazard_color = Color.PURPLE
            pulse_speed = 2.5
        _:
            hazard_color = Color.RED
            pulse_speed = 2.0
    
    setup_hazard_appearance()

# Disable the screen exit behavior since these are static
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
    # Do nothing - static hazards don't exit screen
    pass

# Method to temporarily disable the hazard (if needed for power-ups, etc.)
func set_active(active: bool):
    visible = active
    if collision_shape:
        collision_shape.disabled = !active
    set_process(active)
    set_physics_process(active)
