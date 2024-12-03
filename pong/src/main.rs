#![no_std]
#![no_main]

use sel4_microkit::{Channel, Handler, protection_domain, Infallible};

const PING_CHANNEL: Channel = Channel::new(0);

#[protection_domain]
fn init() -> impl Handler {
    sel4_microkit::debug_println!("Hello! I am pong!");
    return HandlerImpl {};
}

struct HandlerImpl {}

impl Handler for HandlerImpl {
    type Error = Infallible;

    fn notified(&mut self, channel: Channel) -> Result<(), Self::Error> {
        match channel {
            PING_CHANNEL => {
                sel4_microkit::debug_println!("Pong!");
                PING_CHANNEL.notify();
            },
            _ => panic!("Not expecting messages from other channels"),
        }
        Ok(())
    }
}
