#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 resolution;
uniform sampler2D image;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / resolution;
    vec4 color = texture(image, uv);
    
    // Ignore fully transparent pixels
    if (color.a < 0.05) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Un-premultiply alpha so we can analyze pure RGB
    float r = color.r / color.a;
    float g = color.g / color.a;
    float b = color.b / color.a;
    
    bool isBackground = false;
    
    // Catch magenta and all bilinear fringes (Red and Blue dominate Green)
    if (r > g + 0.1 && b > g + 0.1) {
        isBackground = true;
    } 
    // Catch FMI's specific light-purple/grayish artifacts
    else if (r > 0.65 && g > 0.65 && b > 0.85) {
        isBackground = true;
    }
    
    if (isBackground) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    } else {
        float finalR = r;
        float finalG = g;
        float finalB = b;
        
        // Blue shifting logic for actual radar data
        if (b > 0.6) {
            if (g - r <= 0.15) {
               finalR = r * 0.8;
               finalG = min(g * 1.2, 1.0);
            } else {
               finalR = r * 0.4;
               finalG = g * 0.8;
               finalB = b * 0.9;
            }
        }
        
        // Re-premultiply alpha
        fragColor = vec4(finalR, finalG, finalB, 1.0) * color.a;
    }
}
