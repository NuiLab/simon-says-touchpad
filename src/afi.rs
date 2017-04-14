extern crate serial;
extern crate json;

use self::json::JsonValue;
use self::serial::prelude::*;
use std::time::Duration;
use std::fs::OpenOptions;
use std::io::{Read, Write};
use std::error::Error;
use std::str::from_utf8;

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
    buf: Vec<u8>,
    pub output: [f32; 4],
}

impl Input {
    pub fn new() -> Input {
        Input {
            port: create_port(),
            buf: vec![0u8; 32],
            output: [0.; 4],
        }
    }

    // Synchronous Input Update
    pub fn update(&mut self) -> [f32; 4] {

        let mut ftoken: Vec<f32> = Vec::new();

        let mut new_line = String::new();

        loop {

            let mut buf = vec![0u8; 256];

            {
                match self.port.read(&mut buf) {
                    Ok(size) => {
                        if size == 0 {
                            continue;
                        } else {
                            let str_buf = match from_utf8(&mut buf) {
                                Ok(v) => v,
                                Err(e) => panic!("Invalid UTF-8 sequence: {}", e),
                            };

                            new_line.push_str(str_buf);
                        }
                    }
                    Err(_) => continue,
                }
            }

            buf = vec![0u8; 256];

            let tokens: Vec<&str> = new_line.split_whitespace().collect();

            if (tokens.len() >= 4) {
                break;
            }
        }

        // Traverse new_line till we find a \n, then split it there
        let mut token_index = match new_line.find('\n') {
            Some(nl) => nl,
            None => 0
        };

        let tokens = new_line.split_at(token_index).1.split_whitespace();

        for token in tokens {
            match token {
                x => {
                    let f = x.parse::<f32>();
                    match f {
                        Ok(num) => ftoken.push(num),
                        Err(e) => ftoken.push(0.),
                    }

                }
            }
        }

        for (i, t) in ftoken.iter().enumerate() {
            if i < self.output.len() {
                self.output[i] = *t;
            }
        }
        self.buf = vec![0u8; 32];

        self.output
    }
}

fn create_port() -> serial::windows::COMPort {

    use self::SETTINGS;

    let contents = {

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

        contents
    };


    let json_data = match json::parse(&contents) {
        Err(why) => panic!("JSON data couldn't be parsed, verify your JSON."),
        Ok(data) => data,
    };

    let port_name = json_data["port"].as_str();

    let port = match port_name {
        Some(n) => {
            let mut port = match serial::windows::COMPort::open(n) {
                Ok(p) => p,
                Err(why) => panic!("Couldn't setup ports!"),
            };

            port.configure(&SETTINGS);

            port.set_timeout(Duration::from_millis(16));

            port

        }
        None => panic!("Couldn't read ports!"),
    };

    port
}