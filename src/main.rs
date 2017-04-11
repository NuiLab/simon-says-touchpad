extern crate serial;
extern crate glium;

mod afi;

use std::io::Read;
use std::thread::sleep;
use std::time::Duration;

use glium::DisplayBuild;

fn main() {

    // OS Window
    /*
    let window = glium::glutin::WindowBuilder::new()
        .with_fullscreen(glium::glutin::get_primary_monitor())
        .build_glium()
        .unwrap();
    */

        let (mut pa, mut pb) = afi::create_port();

        let mut buf = vec![0u8; 4];

        loop {

            println!("{} {} {} {} ", buf[0], buf[1], buf[2], buf[3]);
            //sleep(Duration::from_millis(16));
            pa.read(&mut buf[..]);
        }

/*
    loop {

        for ev in window.window().poll_events() {
            match ev {
                Event::KeyboardInput(winit::ElementState::Released,
                                     _,
                                     Some(winit::VirtualKeyCode::Escape)) => {
                    println!("Closing visualizer!");
                    return;
                }
                Event::MouseInput(winit::ElementState::Pressed, winit::MouseButton::Left) => {
                    mleft = 1.0;
                }
                Event::MouseInput(winit::ElementState::Released, winit::MouseButton::Left) => {
                    mleft = 0.0;
                }
                Event::MouseMoved(x, y) => {
                    mx = x as f32;
                    my = y as f32;
                }
                Event::Closed => return,
                _ => (),
            }
        }
    }
    */
}

