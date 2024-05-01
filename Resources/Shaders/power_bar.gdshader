shader_type canvas_item;

uniform float fill;

void vertex() {
	//
}

void fragment() {
	if (UV.x >= fill) {
		COLOR.a = 0.2;
	}
	
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
