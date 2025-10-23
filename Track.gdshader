shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

// Albedo
uniform sampler2D albedo_texture : source_color;

// UV Scale
uniform float uv_scale : hint_range(0.1, 10.0) = 1.0;

// Normal Map
uniform sampler2D normal_texture : hint_normal;
uniform float normal_strength : hint_range(0.0, 10.0) = 1.0;

// Roughness
uniform sampler2D roughness_texture : hint_default_white;
uniform float roughness_strength : hint_range(0.0, 2.0) = 1.0;

// Displacement
uniform sampler2D displacement_texture : hint_default_black;
uniform float displacement_strength : hint_range(0.0, 0.1) = 0.05;
uniform float displacement_bias : hint_range(-1.0, 1.0) = 0.0;

// Track (Vehicle Deformation)
uniform sampler2D track_texture : hint_default_black, filter_linear;
uniform float track_intensity : hint_range(0.0, 0.2) = 0.05;
uniform vec3 player_position = vec3(0.0, 0.0, 0.0);
uniform float track_size : hint_range(1.0, 100.0) = 10.0;

// Ambient Occlusion
uniform sampler2D ao_texture : hint_default_white;
uniform float ao_strength : hint_range(0.0, 1.0) = 1.0;

// Metallic
uniform sampler2D metallic_texture : hint_default_black;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

// Specular
uniform sampler2D specular_texture : hint_default_white;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_pos;
varying float vertex_distance;

void vertex() {
	// Scala le UV base
	UV = UV * uv_scale;
	
	// Calcola posizione mondiale del vertice PRIMA delle deformazioni
	vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calcola offset per il calcolo delle normali (adattato alla scala UV)
	float offset = 0.01 / uv_scale;
	vec2 uv_center = UV;
	vec2 uv_right = UV + vec2(offset, 0.0);
	vec2 uv_up = UV + vec2(0.0, offset);
	
	// Offset per le track (in unità mondo)
	float track_offset = track_size * 0.01;
	
	// Track UV basate su coordinate mondiali (piano XZ)
	// Mappa da -track_size/2 a +track_size/2 in coordinate mondo -> 0 a 1 in UV
	vec2 track_uv_center = ((world_vertex.xz - player_position.xz) / track_size) + 0.5;
	vec2 track_uv_right = (((world_vertex.xz + vec2(track_offset, 0.0)) - player_position.xz) / track_size) + 0.5;
	vec2 track_uv_up = (((world_vertex.xz + vec2(0.0, track_offset)) - player_position.xz) / track_size) + 0.5;
	
	// Displacement mapping (alza i vertici lungo la normale)
	float height_center = (texture(displacement_texture, uv_center).r + 
	                       texture(displacement_texture, uv_center).g + 
	                       texture(displacement_texture, uv_center).b) / 3.0;
	float height_right = (texture(displacement_texture, uv_right).r + 
	                      texture(displacement_texture, uv_right).g + 
	                      texture(displacement_texture, uv_right).b) / 3.0;
	float height_up = (texture(displacement_texture, uv_up).r + 
	                   texture(displacement_texture, uv_up).g + 
	                   texture(displacement_texture, uv_up).b) / 3.0;
	
	// Track deformation (usa coordinate globali) - solo se UV sono nel range valido
	float track_center = 0.0;
	float track_right = 0.0;
	float track_up = 0.0;
	
	if (track_uv_center.x >= 0.0 && track_uv_center.x <= 1.0 && 
	    track_uv_center.y >= 0.0 && track_uv_center.y <= 1.0) {
		track_center = (texture(track_texture, track_uv_center).r + 
		                texture(track_texture, track_uv_center).g + 
		                texture(track_texture, track_uv_center).b) / 3.0;
	}
	
	if (track_uv_right.x >= 0.0 && track_uv_right.x <= 1.0 && 
	    track_uv_right.y >= 0.0 && track_uv_right.y <= 1.0) {
		track_right = (texture(track_texture, track_uv_right).r + 
		               texture(track_texture, track_uv_right).g + 
		               texture(track_texture, track_uv_right).b) / 3.0;
	}
	
	if (track_uv_up.x >= 0.0 && track_uv_up.x <= 1.0 && 
	    track_uv_up.y >= 0.0 && track_uv_up.y <= 1.0) {
		track_up = (texture(track_texture, track_uv_up).r + 
		            texture(track_texture, track_uv_up).g + 
		            texture(track_texture, track_uv_up).b) / 3.0;
	}
	
	// Applica displacement e track al vertice centrale
	VERTEX += NORMAL * height_center * displacement_strength;
	VERTEX.y -= track_center * track_intensity;
	
	// Applica un piccolo offset per evitare z-fighting
	VERTEX += NORMAL * displacement_bias * 0.001;
	
	// Calcola le posizioni dei vertici vicini per derivare la normale
	vec3 pos_right = VERTEX + TANGENT * offset;
	pos_right += NORMAL * height_right * displacement_strength;
	pos_right.y -= track_right * track_intensity;
	
	vec3 pos_up = VERTEX + BINORMAL * offset;
	pos_up += NORMAL * height_up * displacement_strength;
	pos_up.y -= track_up * track_intensity;
	
	// Calcola la nuova normale usando il prodotto vettoriale
	vec3 tangent_vec = normalize(pos_right - VERTEX);
	vec3 binormal_vec = normalize(pos_up - VERTEX);
	NORMAL = normalize(cross(tangent_vec, binormal_vec));
	
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calcola la distanza corretta per il depth buffer
	vec4 clip_pos = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(VERTEX, 1.0);
	vertex_distance = clip_pos.z / clip_pos.w;
}

void fragment() {
	// Scrivi il depth corretto
	DEPTH = vertex_distance;
	
	// Albedo/Colore base
	vec4 albedo_tex = texture(albedo_texture, UV);
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	
	// Normal mapping
	vec3 normal_map = texture(normal_texture, UV).rgb;
	NORMAL_MAP = normal_map;
	NORMAL_MAP_DEPTH = normal_strength;
	
	// Roughness
	float roughness_tex = texture(roughness_texture, UV).r;
	ROUGHNESS = roughness_tex * roughness_strength;
	
	// Metallic
	float metallic_tex = texture(metallic_texture, UV).r;
	METALLIC = metallic_tex * metallic;
	
	// Ambient Occlusion
	float ao_tex = texture(ao_texture, UV).r;
	AO = mix(1.0, ao_tex, ao_strength);
	
	// Specular
	float specular_tex = texture(specular_texture, UV).r;
	SPECULAR = specular_tex * specular;
}