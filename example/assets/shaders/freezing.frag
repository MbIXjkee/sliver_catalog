#version 460 core
#define SHOW_GRID

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress;
uniform sampler2D uFreezeTexture;
uniform sampler2D uTargetTexture;

out vec4 fragColor;

bool isFullTransparent(vec4 clr) {
    return clr.a == 0.0 && clr.rgb == vec3(0.0);
}

void main() {
    vec2 xy = FlutterFragCoord().xy;
    vec2 uv = xy / uSize;
    vec2 textureUv = vec2(xy.x, xy.y + uSize.y * (1 - uProgress)) / uSize;

    // Sample the texture
    vec4 textureColor = texture(uFreezeTexture, textureUv);
    // Sample the target
    vec4 targetColor = texture(uTargetTexture, textureUv);

    if(isFullTransparent(targetColor)) {
        fragColor = targetColor;
    } else {
        // Convert the texture to greyscale
        float grey = (textureColor.r + textureColor.g + textureColor.b) / 3.0;

        // Calculate thresholds based on uProgress
        float freezeThreshold = (1.0 - uProgress) * 1.6;
        float edgeThreshold = freezeThreshold - 0.1;

        if(grey > freezeThreshold) {
            fragColor = vec4(0.0);
        } else if(grey > edgeThreshold) {
            fragColor = vec4(0.0, 0.93, 1.0, 1.0);
        } else {
            fragColor = vec4(1.0, 1.0, 1.0, 0.6);
        }
    }
}
