shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture;
uniform float fade: hint_range(0.0, 4.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	
	COLOR = textureLod(screen_tex,SCREEN_UV,fade);
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
