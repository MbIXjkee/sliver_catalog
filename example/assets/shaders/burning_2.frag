#version 460 core
#define SHOW_GRID

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uProgress; // Progress of the burning effect
uniform sampler2D uTexture1;

out vec4 fragColor;

void main() {
    vec2 xy = FlutterFragCoord().xy;
    vec2 uv = xy / uSize;
    vec2 textureUv = vec2(xy.x, xy.y + uSize.y * (1 - uProgress)) / uSize;

    // Sample the texture
    // vec4 textureColor = texture(uTexture1, uv);
    vec4 textureColor = texture(uTexture1, textureUv);

    // Convert the texture to greyscale
    float grey = (textureColor.r + textureColor.g + textureColor.b) / 3.0;

    // Calculate thresholds based on uProgress
    float burnThreshold = 1.0 - uProgress; 
    float edgeThreshold = burnThreshold - 0.1; // Adjust this value for wider/narrower edge

    // Applying the thresholds
    if (grey > burnThreshold) {
        // This part of the image remains untouched
        fragColor = vec4(0.0); // Greyscale color
    } else if (grey > edgeThreshold) {
        // This part of the image is on the burning edge
        fragColor = vec4(1.0, 0.5, 0.0, 1.0); // Orange color for the edge
    } else {
        // This part of the image is completely burned
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black color for burned area
    }
}
