#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Size of the child
uniform vec2 uOffset;       // Offset of the child in canvas
uniform float uProgress;    // shader application progress from 0 (nothing) -> 1 (full)

out vec4 fragColor;

float estimateBloodBoundaryDist(vec2 pp, float prog, out bool blood) {
    pp.y += 0.4 * sin(0.5 * 2.3 * pp.x + pp.y) +
        0.2 * sin(0.5 * 5.5 * pp.x + pp.y) +
        0.1 * sin(0.5 * 13.7 * pp.x) +
        0.06 * sin(0.5 * 23.0 * pp.x);

    const float staticThresh = 5.3;
    float dynThresh = staticThresh * prog;

    blood = (pp.y < dynThresh);

    return abs(pp.y - dynThresh);
}

void main() {
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        discard;
    }

    float aspect = uSize.x / uSize.y;
    vec2 pp = uv * vec2(aspect, 1.0) * 4.0;

    bool isBlood;
    float dist = estimateBloodBoundaryDist(pp, uProgress, isBlood);

    if(isBlood) {
        // ширина «обводки»
        const float edgeWidth = 0.1;
        // простая «маска» края [1.0 в самой границе, 0.0 дальше]
        float edgeT = clamp((edgeWidth - dist) / edgeWidth, 0.0, 1.0);

        // базовый цвет крови
        vec3 bloodCol = vec3(0.6, 0.05, 0.05);
        // добавляем лёгкий светящийся ободок
        bloodCol += edgeT * vec3(0.2, 0.1, 0.1);

        fragColor = vec4(bloodCol, 1.0);
    } else {
        discard;
    }
}
