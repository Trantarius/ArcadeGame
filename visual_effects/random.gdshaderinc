
uint[6] init_rand_state(uint seed){
	return uint[6](
		uint(0xff4e054c) ^ seed,
		uint(0xd7524d08) ^ seed,
		uint(0x9df8b8d6) ^ seed,
		uint(0xf8f9ce57) ^ seed,
		uint(0x46c9e2dc) ^ seed,
		uint(0xfadb3461) ^ seed
	);
}

//https://en.wikipedia.org/wiki/Xorshift#xorwow
uint xorwow(inout uint[6] state)
{
    /* Algorithm "xorwow" from p. 5 of Marsaglia, "Xorshift RNGs" */
    uint t  = state[4];
 
    uint s  = state[0];  /* Perform a contrived 32-bit shift. */
    state[4] = state[3];
    state[3] = state[2];
    state[2] = state[1];
    state[1] = s;
 
    t ^= t >> uint(2);
    t ^= t << uint(1);
    t ^= s ^ (s << uint(4));
    state[0] = t;
    state[5] += uint(362437);
    return t + state[5];
}

float randf(inout uint[6] state){
	uint u = xorwow(state);
	u = (u&uint(0xffff))^(u>>uint(16));
	return float(u)/float(0xffff);
}

vec2 randfn(inout uint[6] state){
	vec2 U = vec2(randf(state),randf(state));
	return vec2( sqrt(-2.0 * log(U.x)) * cos(TAU*U.y),
				 sqrt(-2.0 * log(U.x)) * sin(TAU*U.y));
}