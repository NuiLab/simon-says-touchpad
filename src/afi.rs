extern crate serial;
extern crate json;

use self::serial::prelude::*;
use std::time::Duration;
use std::fs::OpenOptions;
use std::io::{Read, Write};
use std::error::Error;

const DEFAULTCONFIG: &str = "\
{ 
    \"port\": \"\"
}";

const SETTINGS: serial::PortSettings = serial::PortSettings {
    baud_rate: serial::Baud9600,
    char_size: serial::Bits8,
    parity: serial::ParityNone,
    stop_bits: serial::Stop1,
    flow_control: serial::FlowNone,
};

pub struct Input {
    port: serial::windows::COMPort,
    buf: [u8; 256],
    pub output: [f32; 4]
}

impl Input {
    pub fn new() -> Input {
        let port = create_port();
        Input {
            port,
            buf: [0u8; 256],
            output: [0.; 4]
        }
    }

    pub fn update(&self) -> [f32; 4] {
        return self.output;
    }
}


fn create_port() -> serial::windows::COMPort {

    use self::SETTINGS;

    let json_data = {
        use std::io::Error;

        let open = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open("config.json");

        let mut contents = String::new();

        let mut file = match open {
            Err(_) => panic!("Couldn't open the config file!"),
            Ok(file) => file,
        };

        match file.read_to_string(&mut contents) {
            Err(why) => panic!("couldn't read config.json: {}", why.description()),
            Ok(_) => println!("Opened config.json file."),
        }
        if contents.is_empty() {

            contents.insert_str(0, DEFAULTCONFIG);

            match file.write_all(contents.as_bytes()) {

                Err(why) => panic!("couldn't write to config.json: {}", why.description()),
                Ok(_) => println!("Wrote default configuration to file!"),
            }
        }

    json::parse(&contents);
    
    };


    let port_name = json_data["port"].as_str();

    let port = match port_name {
        Ok(n) => {
                let mut port = match serial::windows::COMPort::open(n) {
        Ok(p) => p,
        Err(why) => panic!("Couldn't setup ports!"),
    };

    port.configure(&SETTINGS);

    port.set_timeout(Duration::from_millis(16));

    port

        }
        Err(why) => panic!("Couldn't read ports!")
    }

}