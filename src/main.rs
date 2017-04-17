#[macro_use]
extern crate glium;

mod afi;
mod graphics;

use std::io::Read;
use std::thread::sleep;
use std::time::Duration;

use graphics::Event;

fn main() {

    // AFI Setup
    let mut input = afi::Input::new();

    // Renderer
    let fs = include_str!{concat!(env!("CARGO_MANIFEST_DIR"), "/src/shaders/frag.glsl")};

    let mut renderer = graphics::Renderer::new(fs, [0f32; 4]);

    let mut run = true;

    while run {
        renderer.update(input.update(), |event: &Event| {
            match event {
                &Event::KeyboardInput(glium::glutin::ElementState::Released,_, Some(glium::glutin::VirtualKeyCode::Escape)) => {
                    run = false;
                },
                &Event::Closed => return,
                _ => (),
            }
        });
    }
}
