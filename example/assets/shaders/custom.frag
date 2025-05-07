#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // размер спрайта
uniform vec2 uOffset;     // смещение в канвасе
// 1.0 — начало (кровь не течёт), 0.0 — конец (всё стекло)
uniform float uProgress;

out vec4 fragColor;

// DE: только «волны» по X, без вертикального смещения pp
// blood = true там, где (pp.y + волна) < dynThresh
float DE(vec2 pp, out bool blood, float prog) {
    // твои волны
    pp.y += 0.4 * sin(0.5 * 2.3 * pp.x + pp.y) +
        0.2 * sin(0.5 * 5.5 * pp.x + pp.y) +
        0.1 * sin(0.5 * 13.7 * pp.x) +
        0.06 * sin(0.5 * 23.0 * pp.x);

    const float staticThresh = 5.3;
    // порог движется сверху вниз: при prog=1→ thresh=0, при prog=0→ thresh=5.3
    float dynThresh = staticThresh * (1.0 - prog);

    blood = (pp.y < dynThresh);
    return abs(pp.y - dynThresh);
}

void main() {
    // нормализованный uv (0,0 в левом-верхнем, y→вниз)
    vec2 xy = FlutterFragCoord().xy - uOffset;
    vec2 uv = xy / uSize;
    if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        discard;
    }

    // переводим uv в «DE-координаты»
    float aspect = uSize.x / uSize.y;
    vec2 pp = uv * vec2(aspect, 1.0) * 4.0;

    bool isBlood;
    DE(pp, isBlood, uProgress);

    if(isBlood) {
        fragColor = vec4(0.6, 0.05, 0.05, 1.0);
    } else {
        discard;
    }
}
