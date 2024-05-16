shader_type canvas_item;

// time it takes diffusion to travel to the edge of the canvas item's rect
uniform float diffusion_time = 1.0;
// controls the acceleration of diffusion; <0 is accelerating, 0 is linear, >0 is decelerating
uniform float diffusion_power = 0.0;
// alpha multiplier based on diffusion progress; subject to diffusion_power
uniform sampler2D diffusion_alpha : filter_linear, repeat_disable, hint_default_white;
// noise tex to alter diffusion rate
uniform sampler2D diffusion_noise : filter_linear, repeat_disable, hint_default_black;
uniform float diffusion_noise_strength : hint_range(0,1) = 0.1;

// time it takes for activation of a pixel to complete once started
uniform float activation_time = 0.1;
// controls the acceleration of activation; <0 is accelerating, 0 is linear, >0 is decelerating
uniform float activation_power = 0.0;
// alpha multiplier based on activation progress; subject to activation_power
uniform sampler2D activation_alpha : filter_linear, repeat_disable, hint_default_transparent;
// noise tex to alter activation rate
uniform sampler2D activation_noise : filter_linear, repeat_disable, hint_default_black;
uniform float activation_noise_strength : hint_range(0,1) = 0.1;

// color gradient, where x-axis is activation progress and y-axis is diffusion progress
uniform sampler2D color_plane : source_color, filter_linear, repeat_disable, hint_default_white;

// forcibly sets progress. negative values use TIME, so it can be animated in the editor.
uniform float current_time = -1;

varying float time;

bool is_tex_present(sampler2D tex){
	// the default texture is 4x4
	return textureSize(tex,0).x > 4 || textureSize(tex,0).y > 4;
}

void vertex() {
	if(current_time<0.0){
		time = mod(TIME,diffusion_time+activation_time);
	}
	else{
		time = current_time;
	}
}

void fragment() {
	
	vec2 pos = UV*2.0-1.0;
	float nval = texture(diffusion_noise,UV).r;
	float diffusion = (length(pos) + nval*diffusion_noise_strength);
	diffusion = diffusion_power==0.0 ? diffusion : (exp(diffusion_power * diffusion)-1.0)/(exp(diffusion_power)-1.0);
	float act_start_time = diffusion * diffusion_time;
	
	nval = texture(activation_noise,UV).r;
	float activation = clamp((max(time - act_start_time, 0.0)/activation_time)*(1.0 + activation_noise_strength*nval),0,1);
	activation = activation_power==0.0 ? activation : (exp(-activation_power * activation)-1.0)/(exp(-activation_power)-1.0);
	
	COLOR *= texture(color_plane, vec2(activation, diffusion));
	
	// get from tex, or default to a linear activation alpha
	float alpha = is_tex_present(activation_alpha) ? texture(activation_alpha,vec2(activation,0)).r : mod(1.0-activation,1);
	COLOR.a *= texture(diffusion_alpha,vec2(diffusion,0)).r * alpha;
}
