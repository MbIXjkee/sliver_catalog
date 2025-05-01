#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // Размер объекта (child.size)
uniform vec2 uOffset;       // Смещение child’а в канвасе (paintChildOffset)
uniform float uProgress;    // paintedChildSize / childExtent
uniform sampler2D uFreezeTexture;

out vec4 fragColor;

// Быстрый старт, медленный конец
float easeOutQuad(float x) {
    return 1.0 - (1.0 - x) * (1.0 - x);
}

void main() {
    // Координата фрагмента минус смещение → локальная внутри объекта
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;

    // Получаем текстуру в относительных координатах
    vec4 freezeTex = texture(uFreezeTexture, uv);
    float mask = dot(freezeTex.rgb, vec3(0.299, 0.587, 0.114));

    // Прогресс заморозки
    float freezeStart = 1.0;
    float freezeEnd = 0.3;
    float normalized = clamp((freezeStart - uProgress) / (freezeStart - freezeEnd), 0.0, 1.0);
    float easedProgress = easeOutQuad(normalized);
    float freezeThreshold = mix(0.0, 1.0, easedProgress);
    float edgeWidth = 0.1;

    float t = smoothstep(freezeThreshold, freezeThreshold - edgeWidth, mask);

    float maxAlpha = 0.45;
    vec4 iceColor = freezeTex;
    iceColor.a *= t * maxAlpha;

    fragColor = (t < 0.01) ? vec4(0.0) : iceColor;
}