shader_type spatial;

const float model_height = 0.57;
const float model_rad = 0.285;

uniform float fill;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float height_on_model = (world_position.y - (NODE_POSITION_WORLD.y - model_rad)) / model_height;
	vec4 currentColor = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (height_on_model <= fill) {
		currentColor.rgb = mix(currentColor.rgb,vec3(.729, 0.345, 0.141),.5);
		//EMISSION = vec3(.25, 0.05, 0.025);
	}
	ALBEDO = currentColor.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
