shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture;
uniform float blur;

void fragment() {
	
	vec4 avg;
	vec4 tot;
	
	for(float dx=floor(-blur*2.0);dx<=ceil(blur*2.0);dx+=1.0){
			float weight = exp(-dx*dx/blur/blur);
			vec4 pxl = texture(screen_tex,SCREEN_UV+vec2(dx,0)*SCREEN_PIXEL_SIZE);
			weight*=dot(pxl,pxl);
			avg += pxl*weight;
			tot += weight;
	}
	COLOR = (avg)/tot;
}
