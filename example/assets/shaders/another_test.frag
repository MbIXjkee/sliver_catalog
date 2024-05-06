#version 460 core
#define SHOW_GRID

#include <flutter/runtime_effect.glsl>

uniform vec4 uColor; // line color of the shape

out vec4 fragColor;

void main() {
    fragColor = uColor;
}