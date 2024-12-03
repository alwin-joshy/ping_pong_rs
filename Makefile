BUILD ?= build
BOARD ?= qemu_virt_aarch64

ifeq ($(strip $(MICROKIT_SDK)),)
$(error MICROKIT_SDK must be specified)
endif

BUILD_DIR := $(BUILD)

.PHONY: none
none:

.PHONY: clean
clean:
	rm -rf $(BUILD)

$(BUILD_DIR):
	mkdir -p $@

MICROKIT_BOARD := $(BOARD)
MICROKIT_CONFIG := debug
#microkit_sdk_config_dir := $(MICROKIT_SDK)/board/$(microkit_board)/$(microkit_config)
BOARD_DIR := $(MICROKIT_SDK)/board/$(MICROKIT_BOARD)/$(MICROKIT_CONFIG)
sel4_include_dirs := $(BOARD_DIR)/include


TOOLCHAIN := aarch64-none-elf
CC := $(TOOLCHAIN)-gcc
LD := $(TOOLCHAIN)-ld
AS := $(TOOLCHAIN)-as
MICROKIT_TOOL ?= $(MICROKIT_SDK)/bin/microkit
CFLAGS := -mstrict-align -nostdlib -ffreestanding -g3 -O3 -Wall  -Wno-unused-function -Werror -I$(BOARD_DIR)/include
LDFLAGS := -L$(BOARD_DIR)/lib
LIBS := -lmicrokit -Tmicrokit.ld
IMAGE_FILE = $(BUILD_DIR)/loader.img
REPORT_FILE = $(BUILD_DIR)/report.txt

# Build ping
PING_OBJS := ping.o

$(BUILD_DIR)/%.o: %.c Makefile $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/ping.elf: $(addprefix $(BUILD_DIR)/, $(PING_OBJS))
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@


# Build pong
crate := $(BUILD_DIR)/pong.elf

$(crate): $(crate).intermediate

.INTERMDIATE: $(crate).intermediate
$(crate).intermediate:
	SEL4_INCLUDE_DIRS=$(abspath $(sel4_include_dirs)) \
		cargo build \
			--manifest-path pong/Cargo.toml \
			-Z unstable-options \
			-Z build-std=core,compiler_builtins \
			-Z build-std-features=compiler-builtins-mem \
			--target-dir $(BUILD_DIR)/target \
			--out-dir $(BUILD_DIR) \
			--target pong/support/targets/aarch64-sel4-microkit-minimal.json \
			--release

# Image
#
loader := $(BUILD_DIR)/loader.img
system_description = pingpong.system

$(loader): $(system_description) $(BUILD_DIR)/ping.elf $(BUILD_DIR)/pong.elf
	$(MICROKIT_SDK)/bin/microkit \
		$< \
		--search-path $(BUILD_DIR) \
		--board $(MICROKIT_BOARD) \
		--config $(MICROKIT_CONFIG) \
		-r $(BUILD_DIR)/report.txt \
		-o $@


#Run

qemu_cmd := \
	qemu-system-aarch64 \
		-machine virt,virtualization=on -cpu cortex-a53 -m size=2G \
		-serial mon:stdio \
		-nographic \
		-device loader,file=$(loader),addr=0x70000000,cpu-num=0

.PHONY: run
run: $(loader)
	$(qemu_cmd)
