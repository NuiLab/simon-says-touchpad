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
    let input = afi::Input::new();

    // Renderer
    let fs = r"\
// Uniforms for time, mouse position, resolution, 
// etc are prepended by the renderer.

void main() {
    outColor = vec4(1.);
}
";
    let renderer = graphics::Renderer::new(fs, [0f32; 4]);

    loop {
        match renderer.update(input.update()) {
            Event::Closed => return,
            _ => (),
        }
    }
}
