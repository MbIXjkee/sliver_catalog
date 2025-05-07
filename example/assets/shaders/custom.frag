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
// псевдо-2D noise
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
    // нормализованные координаты внутри спрайта
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        discard;
    }

    // p = 0…1 заполнение (инверсия прогресса)
    float p = 1.0 - uProgress;

    // плавное появление волны первые 10% p
    float waveAppear = smoothstep(0.0, 0.1, p);
    float rawWave = 0.02 * sin(uv.x * 30.0) + 0.015 * fbm(vec2(uv.x * 8.0, p * 5.0));
    rawWave = max(rawWave, 0.0);
    float threshold = clamp(p + rawWave * waveAppear, 0.0, 1.0);

    // параметры капель
    const float DROP_SEGMENTS = 20.0;
    const float NO_DROP_RATIO = 0.3;
    float seg = floor(uv.x * DROP_SEGMENTS);
    float seed = hash(seg);
    bool hasDrop = seed > NO_DROP_RATIO;
    float normS = hasDrop ? (seed - NO_DROP_RATIO) / (1.0 - NO_DROP_RATIO) : 0.0;
    float dropSpeed = mix(0.1, 1.0, normS);

    // форма и длина капли
    float dropNoise = fbm(vec2(uv.x * 20.0, p * 10.0));
    float dropLen = dropNoise * p * 0.5 * dropSpeed;
    float finalT = clamp(threshold + dropLen, 0.0, 1.0);

    // сегментная геометрия
    float segW = 1.0 / DROP_SEGMENTS;
    float radius = segW * 0.5;
    float cx = (seg + 0.5) * segW;

    // проверяем, достигла ли капля нижней границы
    float eps = 1e-4;
    bool atBottom = finalT >= 1.0 - eps;

    vec3 bloodColor = vec3(0.6, 0.05, 0.05);

    // обычная отрисовка до достижения дна
    if(!atBottom) {
        // тело
        if(uv.y < threshold) {
            fragColor = vec4(bloodColor, 1.0);
        }
        // стебель капли
        else if(hasDrop && uv.y < finalT - radius) {
            fragColor = vec4(bloodColor, 1.0);
        }
        // округлая головка
        else if(hasDrop) {
            vec2 d = uv - vec2(cx, finalT - radius);
            if(d.x * d.x + d.y * d.y <= radius * radius) {
                fragColor = vec4(bloodColor, 1.0);
            } else {
                discard;
            }
        } else {
            discard;
        }
    }
    // когда капля упёрлась в дно — начинается растекание
    else {
        // всё, что выше линии заполнения — обычная заливка
        if(uv.y < threshold) {
            fragColor = vec4(bloodColor, 1.0);
        }
        // переходная зона от головки к растеканию
        else if(uv.y < finalT) {
            // полукруглая головка, но обрезанная вполовину
            vec2 d = uv - vec2(cx, finalT - radius);
            if(d.x * d.x + d.y * d.y <= radius * radius && uv.y < finalT - radius * 0.5) {
                fragColor = vec4(bloodColor, 1.0);
            } else {
                // начинаем растекаться уже в этой зоне
                float mixY = (uv.y - (finalT - radius * 0.5)) / (radius * 1.5);
                float spread = mix(radius, segW * 1.5, clamp(mixY, 0.0, 1.0));
                if(abs(uv.x - cx) < spread) {
                    fragColor = vec4(bloodColor, 1.0);
                } else {
                    discard;
                }
            }
        }
        // зона растекания по дну
        else {
            float spreadY = uv.y - finalT;
            float mixY = clamp(spreadY / (radius * 1.5), 0.0, 1.0);
            float spread = mix(radius, segW * 1.5, mixY);
            if(abs(uv.x - cx) < spread) {
                fragColor = vec4(bloodColor, 1.0);
            } else {
                discard;
            }
        }
    }
}
