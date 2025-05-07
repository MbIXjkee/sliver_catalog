#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // размер спрайта
uniform vec2 uOffset;    // смещение в канвасе
uniform float uProgress;  // [0.0 — на экране, 1.0 — почти ушёл]

out vec4 fragColor;

// 1D-хеш для случайности
float hash(float x) {
    return fract(sin(x * 123.456) * 45678.9);
}

// псевдо-2D-noise
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = hash(i.x + i.y * 57.0);
    float b = hash(i.x + 1.0 + i.y * 57.0);
    float c = hash(i.x + (i.y + 1.0) * 57.0);
    float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// лёгкий FBM (3 октейва)
float fbm(vec2 p) {
    float sum = 0.0, amp = 1.0;
    for(int i = 0; i < 3; ++i) {
        sum += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return sum;
}

void main() {
    // UV в [0..1]
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        discard;
    }

    // p ∈ [0..1] — доля заполнения (0 — без крови, 1 — полностью)
    float p = 1.0 - uProgress;

    // плавное появление волны за первые 10% p
    float waveAppear = smoothstep(0.0, 0.1, p);

    // «сырая» волна (+FBM)
    float rawWave = 0.02 * sin(uv.x * 30.0) + 0.015 * fbm(vec2(uv.x * 8.0, p * 5.0));
    // запрещаем отрицательные «впадины», чтобы капли не «ползли вверх»
    rawWave = max(rawWave, 0.0);

    // порог фронта крови
    float threshold = clamp(p + rawWave * waveAppear, 0.0, 1.0);

    //
    // === капли ===
    //
    const float DROP_SEGMENTS = 20.0;  // число вертикальных сегментов
    const float NO_DROP_RATIO = 0.3;   // 30% сегментов без капель
    const float MIN_DROP_SPEED = 0.2;   // минимальная скорость стекания
    const float MAX_DROP_SPEED = 1.0;   // максимальная скорость

    // определяем сегмент и его seed
    float seg = floor(uv.x * DROP_SEGMENTS);
    float seed = hash(seg);

    // решаем, будет ли капля в этом сегменте
    bool hasDrop = (seed > NO_DROP_RATIO);
    // нормализуем seed для диапазона [NO_DROP_RATIO..1] → [0..1]
    float normS = clamp((seed - NO_DROP_RATIO) / (1.0 - NO_DROP_RATIO), 0.0, 1.0);

    // скорость стекания этого сегмента
    float dropSpeed = mix(MIN_DROP_SPEED, MAX_DROP_SPEED, normS);

    // фаза стекания: начинает расти сразу, но с разницей в seed
    float dropPhase = hasDrop ? smoothstep(0.0, 1.0, p * dropSpeed) : 0.0;

    // шум для формы капли
    float dropNoise = fbm(vec2(uv.x * 20.0, p * 10.0));
    // длина капли (максимум ~0.5 в UV-коорд.)
    float dropLen = dropPhase * dropNoise * 0.5 * p;
    float finalT = clamp(threshold + dropLen, 0.0, 1.0);

    // единый цвет крови
    vec3 bloodColor = vec3(0.6, 0.05, 0.05);

    // отрисовываем всё до finalT одним цветом
    if(uv.y < finalT) {
        fragColor = vec4(bloodColor, 1.0);
    } else {
        discard;
    }
}
