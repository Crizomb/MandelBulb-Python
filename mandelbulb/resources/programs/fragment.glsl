#version 330 core
#include hg_sdf.glsl
layout (location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform vec3 ro;
uniform mat3 cam;

const float FOV = 2;
const int MAX_STEPS = 256;
const float MAX_DIST = 500;
const float EPSILON = 0.0005;
const float DIST_CAM = 2;

float packColor(vec3 color) {
    return color.r + color.g * 256.0 + color.b * 256.0 * 256.0;
}

vec3 unpackColor(float f) {
    vec3 color;
    color.b = floor(f / 256.0 / 256.0);
    color.g = floor((f - color.b * 256.0 * 256.0) / 256.0);
    color.r = floor(f - color.b * 256.0 * 256.0 - color.g * 256.0);
    // now we have a vec3 with the 3 components in range [0..255]. Let's normalize it!
    return color / 255.0;
}

vec3 fOpUnionChamferId(vec3 res1, vec3 res2, float r) {
    float a = res1.x;
    float b = res2.x;

	return vec3(min(min(a, b), (a - r + b)*sqrt(0.5)), res1.yz);
}

vec3 fOpDifferenceId(vec3 res1, vec3 res2) {
    return (res1.x > -res2.x) ? res1 : vec3(-res2.x, res2.yz);
}

vec3 fOpUnionId(in vec3 res1, in vec3 res2){
    return (res1.x < res2.x) ? res1 : res2;
}


vec3 map(in vec3 p){
    //pMod3(p, vec3(10.0));

    float planeId = 1;
    float planeColor = packColor(vec3(50, 50, 50));
    float planeDist = fPlane(p, vec3(0, 1, 0), 1.0);
    vec3 plane = vec3(planeDist, planeColor, planeId);

    float sphereId = 2;
    float sphereColor = packColor(vec3(200, 0, 0));
    vec3 spherePos = vec3(2.0, 0.0, 0.0);
    float sphereDist = fSphere(p-spherePos, 1);
    vec3 sphere = vec3(sphereDist, sphereColor, sphereId);

    float playerId = 3;
    float playerColor = packColor(vec3(0, 200, 0));;
    vec3 playerPos = ro+vec3(0, -1, DIST_CAM);
    float playerDist = fCapsule(p-playerPos, 0.2, 0.2);
    vec3 player = vec3(playerDist, playerColor, playerId);

    float mandelBulbId = 3;
    float mandelBulbColor = packColor(vec3(50, 50, 50));;
    float mandelBulbDist = fmandelBulbe(p);;
    vec3 mandelBulb = vec3(mandelBulbDist, mandelBulbColor, mandelBulbId);;

    //vec3 res = fOpUnionId(plane, sphere);
    vec3 res = mandelBulb;
    //res = fOpUnionId(res, mandelBulb);


    return res;
}

vec4 rayMarch(vec3 ro, vec3 rd) {
    vec3 hit = vec3(0.0);
    vec3 object = vec3(0.0);
    vec3 p = vec3(0.0);
    float compt = 0;
    for (float i = 0; i < MAX_STEPS; i++) {
        p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.yz = hit.yz;
        if (hit.z == 2 || hit.z == 3) compt += 1;

        if (abs(hit.x) < EPSILON || object.x > MAX_DIST){
            if (hit.z != 2) return vec4(object, compt);
            return vec4(object, 0);
        }
    }
    return vec4(object, compt);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
    return normalize(n);
}

vec3 getLight(vec3 p, vec3 rd, vec3 color) {
    vec3 lightPos = vec3(10.0, 55.0, -20.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = color * clamp(dot(L, N), 0.0, 1.0);
    vec3 ambient = color * 0.05;
    vec3 fresnel = 0.25 * color * pow(1.0 + dot(rd, N), 3.0);

    // shadows
    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    if (d < length(lightPos - p)) return ambient + fresnel;

    return diffuse + ambient + specular + fresnel;
}

vec3 getMaterial(vec3 p, float color_pack, float id) {
    vec3 m = vec3(0.0);
    vec3 color = unpackColor(color_pack);
    switch (int(id)) {
        case 1:
        m = vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)); break;
    }
    return color+m;
    return color;
}




void render(inout vec3 col, in vec3 ro, in mat3 cam, in vec2 uv) {
    vec3 r1 = vec3(0, 0, 1);
    vec3 lookAt = ro + r1;
    vec3 rd = cam*normalize(vec3(uv, FOV));
    vec4 result = rayMarch(ro, rd);
    vec3 object = result.xyz;
    vec3 glowing_color = vec3(0.5, 0, 0);
    float nb_itter = result.w;



    vec3 background = vec3(0, 0, 0);
    if (object.x < MAX_DIST) {
        vec3 p = ro + object.x * rd;
        vec3 material = getMaterial(p, object.y, object.z);
        col += getLight(p, rd, material);
        // fog
        col = mix(col, background, 1.0 - exp(-0.00002 * object.x * object.x));

    } else {
        // col += background - max(0.9 * rd.y, 0.0);
        col = col;
    }
    float glow_fact = smoothstep(0, MAX_STEPS, nb_itter);
    col += glowing_color*glow_fact;
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution.xy) / u_resolution.y;

    vec3 col;
    render(col, ro, cam, uv);

    // gamma correction
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col, 1.0);
}
