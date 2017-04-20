#[macro_use]
extern crate glium;

mod afi;
mod engine;
mod graphics;

use graphics::Event;

fn main() {

    println!("🙈🙉🙊 AFI Simon Says Game | Version 0.1.0");

    // Simon Says Game
    let mut game = engine::Game::new();

    // Renderer
    let fs = include_str!{concat!(env!("CARGO_MANIFEST_DIR"), "/src/shaders/frag.glsl")};

    let mut renderer = graphics::Renderer::new(fs);

    // Loop
    let mut run = true;

    while run {
        renderer.update(game.update(), |event: &Event| {
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
