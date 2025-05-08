#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Size of the child
uniform vec2 uOffset;       // Offset of the child in canvas
uniform float uProgress;    // Shader application progress from 0 (nothing) -> 1 (full)

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        discard;
    }

    vec2 pos = uv * uSize;

    float stripeCenter = uSize.x * uProgress;
    float stripeHalfWidth = uSize.x * 0.02;
    float glowWidth = stripeHalfWidth * 3.0;

    float dx = pos.x - stripeCenter;
    float dist = abs(dx);

    float intensity = exp(-(dist * dist) / (2.0 * glowWidth * glowWidth));
    intensity *= smoothstep(glowWidth, glowWidth * 0.8, dist);

    vec3 lightColor = vec3(1.0, 0.9, 0.6);

    fragColor = vec4(lightColor * intensity, intensity);
}
