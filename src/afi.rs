extern crate serial;

use serial::prelude::*;
use std::time::Duration;

const SETTINGS: serial::PortSettings = serial::PortSettings {
    baud_rate: serial::Baud9600,
    char_size: serial::Bits8,
    parity: serial::ParityNone,
    stop_bits: serial::Stop1,
    flow_control: serial::FlowNone,
};

pub fn create_port() -> serial::windows::COMPort {

    use self::SETTINGS;

    let mut pa = serial::windows::COMPort::open("COM4").expect("Fail alpha port!");
    pa.configure(&SETTINGS);
    pa.set_timeout(Duration::from_millis(1));
    pa
}

