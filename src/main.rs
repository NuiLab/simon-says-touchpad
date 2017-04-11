mod afi;
mod graphics;

use std::io::Read;
use std::thread::sleep;
use std::time::Duration;


fn main() {
    let mut port = afi::create_port();
    let mut buf = vec![0u8; 4];

    loop {
      afi::read(&mut port, &mut buf);
      println!("{} {} {} {} ", buf[0], buf[1], buf[2], buf[3]);
      sleep(Duration::from_millis(16));
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

