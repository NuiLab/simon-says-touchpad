/*!
A quad based renderer used for raymarching techniques. 

> You can render entire worlds with only 2 triangles! ~ Inigo Quilez, Shadertoy

```no_run
mod graphics;

use graphics::Event;

fn main() {
    let renderer = graphics::Renderer::new();

    // Fragment Shader
    renderer.fs = "\
// Uniforms for time, mouse position, resolution, 
// etc are prepended by the renderer.

void main() {
    outColor = vec4(1.);
}
";
    loop {
        match renderer.update() {
            Event::Close => return
            _ => ()
        }
    }
}
```
*/

extern crate glium;

use self::glium::{DisplayBuild, Display, VertexBuffer, IndexBuffer, Program};
use self::glium::index::PrimitiveType;
pub use self::glium::glutin::Event;
use self::glium::Surface;

use std::time::{Duration, Instant};

#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
    uv: [f32; 2],
}

implement_vertex!(Vertex, position, uv);

static VBO: [Vertex; 4] = [Vertex {
                               position: [1.0, -1.0],
                               uv: [1.0, 0.0],
                           },
                           Vertex {
                               position: [-1.0, -1.0],
                               uv: [0.0, 0.0],
                           },
                           Vertex {
                               position: [1.0, 1.0],
                               uv: [1.0, 1.0],
                           },
                           Vertex {
                               position: [-1.0, 1.0],
                               uv: [0.0, 1.0],
                           }];

static IBO: [u16; 6] = [0, 1, 2, 1, 2, 3];

pub struct Renderer<T> {
    pub display: Display,
    program: Program,
    vbo: VertexBuffer<Vertex>,
    ibo: IndexBuffer<u16>,
    mouse: [f32; 4],
    resolution: [f32; 2],
    now: Instant,
    other_uniforms: T,
}


impl<T> Renderer<T> {
    pub fn new(fs: &str, other_uniforms: T) -> Renderer<T> {
        let display = glium::glutin::WindowBuilder::new()
            .with_fullscreen(glium::glutin::get_primary_monitor())
            .build_glium()
            .unwrap();

        let vbo = glium::VertexBuffer::new(&display, &VBO).unwrap();

        let ibo = glium::IndexBuffer::new(&display, PrimitiveType::TriangleStrip, &IBO).unwrap();

        let program = program!(&display, 
      110 => {
            vertex: "
                #version 110
                uniform mat4 matrix;
                attribute vec2 position;
                attribute vec3 color;
                varying vec3 vColor;
                void main() {
                    gl_Position = vec4(position, 0.0, 1.0) * matrix;
                    vColor = color;
                }
            ",

            fragment: "
                #version 110
                varying vec3 vColor;
                void main() {
                    gl_FragColor = vec4(vColor, 1.0);
                }
            "
        }
        )
                .unwrap();

        Renderer {
            display,
            program,
            vbo,
            ibo,
            mouse: [0.; 4],
            resolution: [0.; 2],
            now: Instant::now(),
            other_uniforms,
        }
    }

    pub fn update(&self, other_uniforms: T) {

        let mut target = self.display.draw();

        target.clear_color(0.0, 0.0, 0.0, 0.0);

         let uniforms = uniform! {
            resolution: self.resolution,
            mouse: self.mouse,
            time: self.now.elapsed().as_secs() as f32 + (self.now.elapsed().subsec_nanos() as f32 / 1000000000.0)
        };

        target
            .draw(&self.vbo,
                  &self.ibo,
                  &self.program,
                  &uniforms,
                  &Default::default())
            .unwrap();

        target.finish().unwrap();

        // Poll IO
        for event in self.display.poll_events() {
            match event {
                Event::KeyboardInput(glium::glutin::ElementState::Released,
                                     _,
                                     Some(glium::glutin::VirtualKeyCode::Escape)) => {
                    return;
                }
                Event::MouseInput(glium::glutin::ElementState::Pressed,
                                  glium::glutin::MouseButton::Left) => {
                    self.mouse = [self.mouse[0], self.mouse[1], 1., self.mouse[3]];
                }
                Event::MouseInput(glium::glutin::ElementState::Released,
                                  glium::glutin::MouseButton::Left) => {
                    self.mouse = [self.mouse[0], self.mouse[1], 0., self.mouse[3]];
                }
                Event::MouseMoved(x, y) => {
                    self.mouse = [x as f32, y as f32, self.mouse[2], self.mouse[3]];
                }
                Event::Closed => return,
                _ => (),
            }
        }
    }
}
