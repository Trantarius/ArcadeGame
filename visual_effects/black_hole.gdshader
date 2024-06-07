shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen_tex: hint_screen_texture;
uniform float radius;
uniform float horizon;
uniform sampler2D noise_tex;
uniform float distortion_pow;
uniform vec4 accretion_color : source_color;
uniform float accretion_pow;
uniform float accretion_orbit_bias;
uniform float accretion_emission;
uniform float accretion_orbit_speed;
uniform float accretion_absorb_speed;

varying vec2 vert;
varying vec2 zoom;

void vertex() {
	vert = VERTEX;
	zoom = vec2(CANVAS_MATRIX[0][0],CANVAS_MATRIX[1][1]);
	// Called for every vertex the material is visible on.
}

float atan2(vec2 v){
	return v.x<0.0 ? atan(v.y/v.x)+PI*1.5 : atan(v.y/v.x)+PI*0.5;
}

vec2 raduv(vec2 v){
	v = (v) * pow(length(v),-0.75);
	return vec2(mod(atan2(v)/TAU,1.0), mod(length(v),1.0));
}

void fragment() {
	vec2 pos = vert-radius;
	float dist = (radius-length(pos))/(radius-horizon);
	
	float black = clamp((dist-1.0)*radius,0,1);
	vec2 distort = -zoom * pos * pow(clamp(dist,0,1),distortion_pow);
	vec4 warp = texture(screen_tex, SCREEN_UV + distort * SCREEN_PIXEL_SIZE);
	
	vec2 ruv = (pos - pos * dist)/radius;
	ruv = raduv(ruv);
	float accrete = pow(clamp(dist,0,1),accretion_pow) ;
	float rad_offset = mod(accretion_absorb_speed * TIME/8.0,1.0);
	float orb_offset = mod(1.0/(1.0-accrete + 1.0/accretion_orbit_bias) + accretion_orbit_speed * TIME/8.0,1.0);
	ruv = vec2(mod(ruv.x+orb_offset,1.0), mod(ruv.y+rad_offset,1.0));
	
	float accretion = texture(noise_tex, ruv).r * pow(clamp(dist,0,1),accretion_pow);
	
	COLOR = mix(warp+accretion_color*accretion*accretion_emission,vec4(0,0,0,1),black);
}