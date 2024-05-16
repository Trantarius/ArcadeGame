shader_type particles;

#include "random.gdshaderinc"

uniform float speed=100.0;
uniform vec2 spread=vec2(32.0,0.0);
uniform float drag=1.0;

uniform sampler2D size : repeat_disable, filter_linear;
uniform sampler2D color : source_color, repeat_disable, filter_linear;
uniform vec3 spark_color : source_color;

uniform float spark_chance=0.2;
uniform float spark_size=0.1;
uniform float spark_alpha_mult=3.0;

uniform vec2 base_velocity;


void start() {
	TRANSFORM=mat4(1);
	TRANSFORM[3].xyz=EMISSION_TRANSFORM[3].xyz;
	
	uint[6] rand = init_rand_state(RANDOM_SEED ^ (NUMBER * INDEX));
	
	VELOCITY = vec3(base_velocity,0.0) + mat3(EMISSION_TRANSFORM)*(
		vec3((randf(rand)-0.5)*spread.x,(randf(rand)-0.5)*spread.y,0) + vec3(0,speed,0));
	// age
	CUSTOM.x=0.0;
	if(randf(rand)<spark_chance){
		CUSTOM.z=1.0;
	}else{
		CUSTOM.z=0.0;
	}
}

void process() {
	CUSTOM.x+=DELTA;
	CUSTOM.y=CUSTOM.x/LIFETIME;
	
	if(CUSTOM.z<0.5){
		//smoke
		TRANSFORM[0][0] = texture(size,vec2(CUSTOM.y,0)).r;
		TRANSFORM[1][1] = TRANSFORM[0][0];
		COLOR = texture(color,vec2(CUSTOM.y,0));
	}
	else{
		//spark
		TRANSFORM[0][0] = spark_size;
		TRANSFORM[1][1] = TRANSFORM[0][0];
		COLOR.rgb = spark_color.rgb;
		COLOR.a = texture(color,vec2(CUSTOM.y,0)).a * spark_alpha_mult;
	}
	
	VELOCITY = normalize(VELOCITY) * (length(VELOCITY)-drag*DELTA);
	
	//TRANSFORM[3].xyz += VELOCITY*DELTA;
	// Called every frame on existing particles (according to the Fixed FPS property).
}
