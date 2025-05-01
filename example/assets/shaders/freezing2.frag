#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress; // paintedChildSize / childExtent
uniform sampler2D uFreezeTexture;

out vec4 fragColor;

void main() {
    vec2 xy = FlutterFragCoord().xy;
    vec2 uv = xy / uSize;

    // Скользим вверх по мере уменьшения uProgress, чтобы "заморозка" двигалась вниз
    vec2 shiftedUv = vec2(uv.x, uv.y + (1.0 - uProgress));

    // Используем яркость текстуры как маску замораживания
    vec4 tex = texture(uFreezeTexture, shiftedUv);
    float mask = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

    float freezeThreshold = (1.0 - uProgress) * 1.6;
    float edgeThreshold = freezeThreshold - 0.1;

    if(mask > freezeThreshold) {
        // Ещё не заморожено — полностью прозрачное
        fragColor = vec4(0.0);
    } else if(mask > edgeThreshold) {
        // Край заморозки — усилим яркость и насыщенность
        fragColor = tex * 1.2; // можно добавить легкое свечение
        fragColor.a = tex.a;
    } else {
        // Полностью заморожено — используем как есть
        fragColor = tex;
    }
}
