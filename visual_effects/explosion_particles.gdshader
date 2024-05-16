shader_type particles;

#include "random.gdshaderinc"

uniform float speed = 100.0;
uniform float expansion = 4.0;
uniform float drag = 1.0;
uniform float scale = 1.0;
uniform float tex_scale = 1.0;
uniform float alpha_boost = 0.0;
uniform vec3 color : source_color;

uniform vec3 base_velocity;

void start() {
	TRANSFORM=mat4(1);
	TRANSFORM[3].xyz=EMISSION_TRANSFORM[3].xyz;
	
	uint[6] rand = init_rand_state(RANDOM_SEED ^ ((NUMBER+uint(103)) * (INDEX+uint(73))));
	
	VELOCITY = base_velocity + speed * vec3(randfn(rand),randfn(rand).x);
	VELOCITY *= scale;
	COLOR.rgb = color;
	COLOR.a = 1.0 + alpha_boost;
	
	// age
	CUSTOM.x = 0.0;
	TRANSFORM[0][0] *= scale * tex_scale;
	TRANSFORM[1][1] *= scale * tex_scale;
	TRANSFORM[2][2] *= scale * tex_scale;
}

void process() {
	CUSTOM.x += DELTA;
	
	float expand = pow(expansion,DELTA);
	TRANSFORM[0][0] *= expand;
	TRANSFORM[1][1] *= expand;
	TRANSFORM[2][2] *= expand;
	COLOR.a /= expand*expand;
	COLOR.a = min(COLOR.a, LIFETIME-CUSTOM.x);
	
	float slow = pow(drag,DELTA);
	VELOCITY /= slow;
}
