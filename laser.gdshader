shader_type canvas_item;

uniform sampler2D gradient;
uniform float shade_offset;

varying float fid;

void vertex() {
	fid = min(UV.x,1.0);
}

void fragment() {
	float radial = abs(2.0*UV.y-1.0);
	float line_len = UV.x/fid;
	float linear = 1.0-clamp(2.0*min(UV.x,line_len-UV.x),0,1);
	float shade = clamp(radial+linear + shade_offset,0,1);
	COLOR = texture(gradient,vec2(shade,0));
}