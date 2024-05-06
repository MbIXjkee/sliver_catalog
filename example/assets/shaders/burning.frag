#version 300 es
precision mediump float;

uniform vec2 u_resolution; // Resolution of the shape
uniform float u_progress; // Progress of the burning effect

out vec4 FragColor;

// Simple pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Generate procedural noise based on fragment position
    float noiseValue = random(uv * u_progress);

    // Calculate the burn threshold
    float burnThreshold = 0.5f - u_progress * 0.5f;

    if (noiseValue < burnThreshold) {
        // Burnt area
        FragColor = vec4(0.0, 0.0, 0.0, 0.0); // Render transparent or burnt color
    } else {
        // Unburnt area
        FragColor = vec4(0.97f, 0.69f, 0.3f, 0.68f); // Original paper color
    }
}
