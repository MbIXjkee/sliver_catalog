#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Size of the child
uniform vec2 uOffset;       // Offset of the child in canvas
uniform float uProgress;    // Shader application progress from 0 (nothing) -> 1 (full)

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

    // Calculate the aspect ratio of the child
    float aspect = uSize.x / uSize.y;
    // scale for transition from UV-coordinates to Distance Estimation space
    vec2 uvToDEScale = vec2(aspect, 1.0);
    // A scale factor to allow sinusoids and thresholds to operate with convenient numbers.
    float scaleFactor = 4.0;
    vec2 pp = uv * uvToDEScale * 4.0;

    // Define is this pixel is blood or not, calculating distance for add volume
    // and light effect.
    bool isBlood;
    float dist = estimateBloodBoundaryDist(pp, uProgress, isBlood);

    if(isBlood) {
        // Stroke width.
        const float edgeWidth = 0.1;
        // Simple edge “mask” [1.0 at the edge, 0.0 further away]
        float edgeT = clamp((edgeWidth - dist) / edgeWidth, 0.0, 1.0);

        // A basic blood color.
        vec3 bloodColor = vec3(0.6, 0.05, 0.05);
        // For the edge, we add a light stroke of shine.
        bloodColor += edgeT * vec3(0.2, 0.1, 0.1);

        fragColor = vec4(bloodColor, 1.0);
    } else {
        discard;
    }
}
