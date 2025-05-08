#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Size of the child
uniform vec2 uOffset;       // Offset of the child in canvas
uniform float uProgress;    // Shader application progress from 0 (nothing) -> 1 (full)
uniform sampler2D uFreezeTexture;

out vec4 fragColor;

// Easing function to apply a dynamic to the effect - fast at the beginning and slow at the end.
float easeOutQuad(float x) {
    return 1.0 - (1.0 - x) * (1.0 - x);
}

void main() {
    // Local coordinate of the fragment -> global - offset.
    vec2 xy = FlutterFragCoord().xy - uOffset;
    // Local coordinate relative the texture.
    vec2 uv = xy / uSize;

    // Texture value in the coordinate.
    vec4 freezeTex = texture(uFreezeTexture, uv);
    // Luminance of the texture.
    float mask = dot(freezeTex.rgb, vec3(0.299, 0.587, 0.114));

    // Freezing progress calculation.
    float freezeStart = 0.0;
    float freezeEnd = 0.7;

    // The freezing effect is applied when the progress is between freezeStart and freezeEnd.
    float normalized = clamp((uProgress - freezeStart) / (freezeEnd - freezeStart), 0.0, 1.0);
    // Add easing to the progress to apply a special dynamic to the effect.
    // Calculate the threshold for the freezing effect, for values higher than freezeThreshold,
    // the effect is not applied, for values lower than freezeThreshold, the effect is applied.
    float freezeThreshold = easeOutQuad(normalized);
    float edgeWidth = 0.1;

    // Adding smothness to the effect.
    // Within the edgeWidth range, the effect is applied with a smoothstep function,
    // making the effect more natural.
    float t = smoothstep(freezeThreshold, freezeThreshold - edgeWidth, mask);

    float maxAlpha = 0.45;
    vec4 iceColor = freezeTex;
    iceColor.a *= t * maxAlpha;

    fragColor = (t < 0.01) ? vec4(0.0) : iceColor;
}