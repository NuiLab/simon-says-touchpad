#version 110
s
attribute vec2 position;
attribute vec2 uv;
varying vec2 oUV;

void main() {
    oUV = uv;
    gl_Position = vec4(position, 0.0, 1.0);
}