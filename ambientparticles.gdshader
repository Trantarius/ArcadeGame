shader_type particles;

uniform float width=1024;
uniform float height=1024;
uniform float drift_speed=8;
uniform float fade_time=1;
uniform float parallax=0;

float randf(uint seed, uint n,uint idx){
	seed = seed^(n*uint(12345))^(idx*uint(54321));
	return float(seed%uint(1000))/1000.0;
}

void start() {
	TRANSFORM=mat4(1);
	
	VELOCITY=vec3((randf(RANDOM_SEED,NUMBER,8956)*2.0-1.0)*drift_speed,
				  (randf(RANDOM_SEED,NUMBER,139)*2.0-1.0)*drift_speed,
				  (randf(RANDOM_SEED,NUMBER,963)*2.0-1.0)*drift_speed);
	// age
	CUSTOM.w=0.0;
	// true position
	CUSTOM.xyz = vec3((randf(RANDOM_SEED,NUMBER,567)-0.5)*width,
					  (randf(RANDOM_SEED,NUMBER,4783)-0.5)*height,
					   randf(RANDOM_SEED,NUMBER,93675) * (width+height)/2.0);
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
