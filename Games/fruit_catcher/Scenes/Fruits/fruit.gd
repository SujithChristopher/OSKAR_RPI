extends Area2D
class_name Gem

const INITIAL_SPEED: float = 200.0 
var END_OF_SCREEN_Y: float
signal gem_off_screen

static var gem_count: int = 0

# Directory containing fruit images
const FRUITS_DIR = "res://Games/fruit_catcher/assets/fruits/"
# Cache for loaded textures to improve performance
static var fruit_textures: Array[Texture2D] = []
static var textures_loaded: bool = false

func _init() -> void:
    print("Gem:: _init")

func _enter_tree() -> void:
    print("Gem:: _enter_tree")

func _ready() -> void:
    print("Gem:: _ready")
    gem_count += 1
    print("gem_count = ", gem_count)
    END_OF_SCREEN_Y = get_viewport_rect().end.y
    
    # Load textures only once
    if not textures_loaded:
        load_fruit_textures()
    
    # Set random fruit texture
    set_random_fruit_texture()

func load_fruit_textures() -> void:
    """Load all fruit textures once and cache them"""
    var fruit_files = get_fruit_files()
    fruit_textures.clear()
    
    for file_name in fruit_files:
        var texture_path = FRUITS_DIR + file_name
        var texture = load(texture_path) as Texture2D
        if texture:
            fruit_textures.append(texture)
            print("Loaded texture: ", file_name)
    
    textures_loaded = true
    print("Loaded ", fruit_textures.size(), " fruit textures")

func set_random_fruit_texture() -> void:
    """Set a random fruit texture from the cached textures"""
    if fruit_textures.size() > 0:
        var sprite = get_node("Sprite2D") as Sprite2D
        if sprite:
            var random_index = randi() % fruit_textures.size()
            sprite.texture = fruit_textures[random_index]
            print("Set random fruit texture, index: ", random_index)
    else:
        print("No fruit textures available!")

func get_fruit_files() -> Array[String]:
    var fruit_files: Array[String] = []
    var dir = DirAccess.open(FRUITS_DIR)
    
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            # Check if it's an image file
            if file_name.ends_with(".jpg") or file_name.ends_with(".png") or file_name.ends_with(".jpeg"):
                fruit_files.append(file_name)
            file_name = dir.get_next()
        
        dir.list_dir_end()
    else:
        print("Failed to access directory: ", FRUITS_DIR)
    
    return fruit_files

func die() -> void:
    set_process(false)
    gem_count -= 1  # Decrement counter to prevent memory leak
    print("Gem died, remaining gems: ", gem_count)
    queue_free()

func _process(delta: float) -> void:
    position.y += INITIAL_SPEED * delta
    
    if position.y > END_OF_SCREEN_Y:
        print("Gem fell out of screen")
        gem_off_screen.emit()
        die()

func _on_area_entered(area: Area2D) -> void:
    print("Gem hits paddle")
    die()
