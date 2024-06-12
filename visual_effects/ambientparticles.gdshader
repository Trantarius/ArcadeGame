shader_type particles;

uniform float width=1024;
uniform float height=1024;
uniform float drift_speed=8;
uniform float fade_time=1;
uniform float parallax=0;
uniform float particle_size=1;

#include "random.gdshaderinc"

void start() {
	TRANSFORM=mat4(particle_size);
	
	uint[6] rand = init_rand_state(RANDOM_SEED ^ (NUMBER*uint(1234)+INDEX*uint(4321)));
	
	VELOCITY=vec3((randf(rand)*2.0-1.0)*drift_speed,
				  (randf(rand)*2.0-1.0)*drift_speed,
				  (randf(rand)*2.0-1.0)*drift_speed);
	// age
	CUSTOM.w=0.0;
	// true position
	CUSTOM.xyz = vec3((randf(rand)-0.5)*width,
					  (randf(rand)-0.5)*height,
					   randf(rand) * (width+height)/2.0);
}

void process() {
	CUSTOM.xyz += VELOCITY*DELTA;
	float depth = CUSTOM.z*2.0/(width+height);
	vec2 pos = CUSTOM.xy + (1.0-1.0/(depth*parallax+1.0))*EMISSION_TRANSFORM[3].xy;
	
	pos -= EMISSION_TRANSFORM[3].xy;
	pos.x = mod(pos.x,width)-width/2.0;
	pos.y = mod(pos.y,height)-height/2.0;
	pos += EMISSION_TRANSFORM[3].xy;
	TRANSFORM[3].xy = pos;
	CUSTOM.w+=DELTA;
	COLOR.a=min(CUSTOM.w,LIFETIME-CUSTOM.w)/fade_time;
}
