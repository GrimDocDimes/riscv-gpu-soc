# Firmware Makefile
# RISC-V GCC toolchain

# Toolchain
# For NixOS (nix-shell): riscv32-none-elf-
# For manual install: riscv-none-elf- or riscv32-unknown-elf-
CROSS_COMPILE = riscv32-none-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size

# Flags
ARCH_FLAGS = -march=rv32i -mabi=ilp32
CFLAGS = $(ARCH_FLAGS) -O2 -Wall -Wextra -ffreestanding -nostdlib
ASFLAGS = $(ARCH_FLAGS)
LDFLAGS = -T linker.ld -nostdlib -nostartfiles

# Directories
BOOTLOADER_DIR = bootloader
DRIVER_DIR = drivers
EXAMPLE_DIR = examples
BUILD_DIR = build

# Source files
STARTUP_SRC = $(BOOTLOADER_DIR)/start.S
DRIVER_SRCS = $(DRIVER_DIR)/gpu_driver.c
EXAMPLE_SRCS = $(EXAMPLE_DIR)/test_pattern.c

ALL_SRCS = $(STARTUP_SRC) $(DRIVER_SRCS) $(EXAMPLE_SRCS)

# Object files
OBJS = $(BUILD_DIR)/start.o \
       $(BUILD_DIR)/gpu_driver.o \
       $(BUILD_DIR)/test_pattern.o

# Output
TARGET = firmware
ELF = $(BUILD_DIR)/$(TARGET).elf
BIN = $(BUILD_DIR)/$(TARGET).bin
HEX = $(BUILD_DIR)/$(TARGET).hex
LST = $(BUILD_DIR)/$(TARGET).lst

.PHONY: all clean size

all: $(BIN) $(HEX) $(LST) size

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/start.o: $(STARTUP_SRC) | $(BUILD_DIR)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/gpu_driver.o: $(DRIVER_DIR)/gpu_driver.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/test_pattern.o: $(EXAMPLE_DIR)/test_pattern.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJS) linker.ld
	$(CC) $(LDFLAGS) $(OBJS) -o $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(ELF)
	$(OBJCOPY) -O verilog $< $@

$(LST): $(ELF)
	$(OBJDUMP) -d $< > $@

size: $(ELF)
	@echo "=== Firmware Size ==="
	@$(SIZE) $<

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Firmware Makefile"
	@echo "  make all   - Build firmware"
	@echo "  make clean - Clean build files"
	@echo "  make size  - Show firmware size"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - RISC-V GCC toolchain (riscv32-unknown-elf-gcc)"
	@echo ""
	@echo "Output files:"
	@echo "  $(ELF) - ELF executable"
	@echo "  $(BIN) - Raw binary"
	@echo "  $(HEX) - Verilog hex format"
	@echo "  $(LST) - Disassembly listing"

