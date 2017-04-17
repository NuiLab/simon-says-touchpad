#version 110

attribute vec2 position;
attribute vec2 auv;
varying vec2 uv;

void main()
{
    uv = auv;
    gl_Position = vec4(position, 0.0, 1.0);
}