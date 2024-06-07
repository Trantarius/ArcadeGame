shader_type canvas_item;

#include "noise.gdshaderinc"

varying vec2 pos;
varying vec2 cam_offset;

float nebula(vec3 p){
	p = p/1000.0;
	int l = 0;
	
	vec3 dw = vec3(0);
	vec3 dp = p;
	float value = 0.0;
	float vmx = 0.0;
	
	const float odiff = 2.0;
	const float warp = 0.5;
	
	for(int o=0;o<4;o++){
		dw += vec3( simplex4(vec4(dp,float(l++))), simplex4(vec4(dp,float(l++))), simplex4(vec4(dp,float(l++)))) * warp;
		float oct = simplex4(vec4(dp + dw,float(l++)));
		oct = (oct + 1.0)/2.0;
		oct *= oct;
		value += oct;
		vmx += 1.0 ;
		
		dp *= odiff;
		value *= odiff;
		dw *= odiff;
		vmx *= odiff;
	}
	
	value /= vmx;
	dw/=vmx;
	
	float cloud = simplex4(vec4(p + dw,float(l++)));
	cloud = clamp((cloud-0.5)*2.0,0,1);
	cloud *= cloud*cloud;
	
	return value;
}

void vertex() {
	pos = (MODEL_MATRIX*vec4(VERTEX,0,1)).xy;
	cam_offset = (CANVAS_MATRIX*vec4(0,0,0,1)).xy;
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	
	float cloud = simplex4(vec4(pos,0,0)/1000.0);
	cloud *= cloud;
	//cloud=(cloud + 1.0)/2.0;
	COLOR.rgb = vec3(nebula(vec3(pos,0)));
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
