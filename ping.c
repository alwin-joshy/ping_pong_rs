#include <microkit.h>

#define PONG_CHANNEL 0

void init() {
    microkit_dbg_puts("Hello, I am ping!");
    microkit_notify(PONG_CHANNEL);
}

void notified(microkit_channel ch) {
    switch (ch) {
        case PONG_CHANNEL:
            microkit_dbg_puts("Ping!\n");
            microkit_notify(PONG_CHANNEL);
    }
}
