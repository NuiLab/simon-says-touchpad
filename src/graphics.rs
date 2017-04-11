extern crate glium;

use self::glium::DisplayBuild;
use self::glium::Display;

struct Renderer {
    window: Display,
}

impl Renderer {
    pub fn new() -> Renderer {
        let window = glium::glutin::WindowBuilder::new()
            .with_fullscreen(glium::glutin::get_primary_monitor())
            .build_glium()
            .unwrap();
        Renderer { window }
    }
}

