shader_type spatial;

uniform sampler2D albedo_texture;
uniform float rotation_angle = 0.0; // Rotation in radians
render_mode unshaded, depth_draw_never;

void vertex() {
    //// Get the world position of the node (ignoring parent's rotation)
    //vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
//
    //// Get the camera orientation from INV_VIEW_MATRIX
    //vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz); // Right (X)
    //vec3 camera_up = normalize(INV_VIEW_MATRIX[1].xyz);    // Up (Y)
//
    //// Apply 2D rotation to the quad
    //float cos_r = cos(rotation_angle);
    //float sin_r = sin(rotation_angle);
    //vec2 rotated_pos = vec2(
        //VERTEX.x * cos_r - VERTEX.y * sin_r,
        //VERTEX.x * sin_r + VERTEX.y * cos_r
    //);
//
    //// Reconstruct the vertex position in world space
    //VERTEX = world_pos + rotated_pos.x * camera_right + rotated_pos.y * camera_up;
    //
    //// Convert world space back to local space for rendering
    //VERTEX = (inverse(MODEL_MATRIX) * vec4(VERTEX, 1.0)).xyz;

        // Extract world position of the node (ignoring parent's rotation)
    vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

    // Extract scale from MODEL_MATRIX
    vec3 scale = vec3(
        length(MODEL_MATRIX[0].xyz), // Scale X
        length(MODEL_MATRIX[1].xyz), // Scale Y
        length(MODEL_MATRIX[2].xyz)  // Scale Z (not used)
    );

    // Extract camera orientation from INV_VIEW_MATRIX
    vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz) * scale.x;
    vec3 camera_up = normalize(INV_VIEW_MATRIX[1].xyz) * scale.y;

    // Apply 2D rotation to the quad
    float cos_r = cos(rotation_angle);
    float sin_r = sin(rotation_angle);
    vec2 rotated_pos = vec2(
        VERTEX.x * cos_r - VERTEX.y * sin_r,
        VERTEX.x * sin_r + VERTEX.y * cos_r
    );

    // Reconstruct the vertex position in world space with scaling
    VERTEX = world_pos + rotated_pos.x * camera_right + rotated_pos.y * camera_up;

    // Convert back to local space for rendering
    VERTEX = (inverse(MODEL_MATRIX) * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Sample the texture, clamping UVs to avoid tiling
    vec4 tex_color = texture(albedo_texture, UV);

    ALBEDO = tex_color.rgb;
    ALPHA = tex_color.a;
    EMISSION = tex_color.rgb; // Keep it fully bright (unlit)
    DEPTH = 1.0;
}
