#version 460 core
#define SHOW_GRID

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;  // Size of the shape
uniform float uProgress; // Progress of the overpainting

out vec4 fragColor;

void main() {
    // Normalize the y-coordinate
    float normalizedY = gl_FragCoord.y / uSize.y;

    // Determine if the current fragment is below the progress line
    if (normalizedY <= uProgress) {
        // If it is, set the fragment's color to orange
        fragColor = vec4(1.0, 0.5, 0.0, 1.0); // Opaque orange
    } else {
        // Otherwise, make it transparent or keep the original color
        fragColor = vec4(0.0, 0.0, 0.0, 0.0); // Transparent
    }
}
