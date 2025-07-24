# GameManager.gd - Add this as an AutoLoad singleton
# Project -> Project Settings -> AutoLoad -> Add this script as "GameManager"

extends Node

# Player position storage for level transitions
var stored_player_position: Vector3 = Vector3.ZERO
var has_stored_position: bool = false

# Game constants that might be shared across levels
const FLOOR_Y = -0.328
const MIN_X = -2.321
const MAX_X = 2.059
const MIN_Z = -1.179
const MAX_Z = 3.407

func store_player_position(pos: Vector3):
    """Store player position for level transitions"""
    stored_player_position = pos
    has_stored_position = true
    print("Stored player position: ", pos)

func get_stored_player_position() -> Vector3:
    """Get the stored player position"""
    return stored_player_position

func clear_stored_position():
    """Clear stored position after use"""
    has_stored_position = false
    stored_player_position = Vector3.ZERO

func is_position_within_bounds(pos: Vector3) -> bool:
    """Check if a position is within game boundaries"""
    return pos.x >= MIN_X and pos.x <= MAX_X and pos.z >= MIN_Z and pos.z <= MAX_Z

func clamp_position_to_bounds(pos: Vector3) -> Vector3:
    """Ensure position is within game boundaries"""
    return Vector3(
        clamp(pos.x, MIN_X, MAX_X),
        pos.y,
        clamp(pos.z, MIN_Z, MAX_Z)
    )
