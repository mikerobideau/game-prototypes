shader_type canvas_item;

uniform vec2 mouse_uv = vec2(0.5);

varying float kind;
varying float amt;
varying float hot;

vec3 hsv(float h, float s, float v) {
	vec3 k = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return v * mix(vec3(1.0), k, s);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	kind = 0.0;
	hot = step(0.975, COLOR.a);
	amt = 1.0;
	if (COLOR.r > 0.99 && COLOR.g < 0.01 && COLOR.b > 0.99) {
		kind = 1.0;
	} else if (COLOR.r < 0.01 && COLOR.g > 0.99 && COLOR.b > 0.99) {
		kind = 2.0;
	}
}

void fragment() {
	if (kind > 0.5 && kind < 1.5) {
		vec2 p = UV - 0.5;
		float r = length(p) * 2.0;
		float ring = smoothstep(0.15, 0.19, r) * (1.0 - smoothstep(0.96, 1.0, r));
		float ang = atan(p.y, p.x);
		vec2 tilt = (SCREEN_UV - mouse_uv) * hot;
		float h = fract(ang / 6.2831853 * 2.0 + r * 0.9 + TIME * 0.08 + dot(tilt, vec2(1.4, 0.9)));
		float grooves = 0.5 + 0.5 * sin(r * 170.0);
		float sheen = pow(max(0.0, cos(ang * 2.0 - TIME * 0.7 + tilt.x * 7.0 + tilt.y * 4.0)), 8.0);
		vec3 c = hsv(h, 0.6, 1.0);
		float a = amt * ring * (0.2 + 0.1 * grooves + 0.4 * sheen);
		COLOR = vec4(mix(c, vec3(1.0), sheen * 0.55), a);
	} else if (kind > 1.5) {
		vec2 uv = UV;
		float cr = noise(uv * vec2(8.0, 6.0)) * 0.6 + noise(uv * vec2(21.0, 17.0)) * 0.4;
		float creases = smoothstep(0.42, 0.5, cr) * (1.0 - smoothstep(0.5, 0.58, cr));
		vec2 tilt = (SCREEN_UV - mouse_uv) * hot;
		float band = uv.x * 0.8 + uv.y * 0.6 + tilt.x * 0.9 + tilt.y * 0.5;
		float spec = pow(max(0.0, 1.0 - abs(fract(band * 0.8 + TIME * 0.03) - 0.5) * 5.0), 3.0);
		float edge = 1.0 - smoothstep(0.0, 0.07, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
		float a = amt * (0.09 + 0.4 * spec * (0.6 + 0.8 * cr) + 0.18 * creases + 0.2 * edge);
		COLOR = vec4(vec3(0.97, 0.99, 1.0), a);
	}
}
