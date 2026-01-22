# RISC-V Toolchain Setup - Quick Reference

## Current Status

✅ **shell.nix created** - NixOS development environment configured  
⏳ **Toolchain building** - Nix is compiling RISC-V GCC (this may take 10-20 minutes)  
✅ **Firmware Makefile updated** - Using `riscv32-none-elf-` prefix  

---

## Once Toolchain Build Completes

### Step 1: Enter Development Environment

```bash
cd /home/jhush/riscvgpuacc
nix-shell
```

You'll see a welcome message showing available tools.

### Step 2: Verify Toolchain

```bash
riscv32-none-elf-gcc --version
```

Expected output:
```
riscv32-none-elf-gcc (GCC) 14.x.x
...
```

### Step 3: Build Firmware

```bash
cd firmware
make all
```

This will create:
- `build/firmware.elf` - ELF executable
- `build/firmware.bin` - Raw binary
- `build/firmware.hex` - Verilog hex format
- `build/firmware.lst` - Disassembly listing

### Step 4 (Optional): Run Simulation

```bash
cd ../sim/system
make sim
```

View waveforms:
```bash
make view
```

### Step 5: Synthesize for FPGA

**Prerequisites**: Xilinx Vivado installed

```bash
# Source Vivado settings
source /tools/Xilinx/Vivado/2020.2/settings64.sh

# Run synthesis
cd /home/jhush/riscvgpuacc
./scripts/build_fpga.sh
```

Build time: ~10-20 minutes

Output: `build/riscv_gpu_soc.bit`

### Step 6: Program PYNQ-Z2

```bash
# Copy bitstream to PYNQ
scp build/riscv_gpu_soc.bit xilinx@<pynq-ip>:~/

# SSH to PYNQ
ssh xilinx@<pynq-ip>

# Load bitstream
sudo python3 -c "from pynq import Overlay; Overlay('riscv_gpu_soc.bit')"
```

### Step 7: Verify Display

Connect HDMI cable to monitor. You should see:
- White border around screen
- Three colored rectangles (red, green, blue)
- Diagonal yellow and cyan lines

---

## Quick Start Script

For convenience, use the quick start script:

```bash
nix-shell
./scripts/quickstart.sh
```

This will:
1. Check toolchain availability
2. Build firmware
3. Show next steps

---

## Troubleshooting

### Toolchain not found
- Make sure you're inside `nix-shell`
- Run `nix-shell` from the project root directory

### Firmware build errors
- Check that you're using the correct toolchain prefix
- Verify linker script exists: `firmware/linker.ld`
- Check startup code: `firmware/bootloader/start.S`

### Synthesis errors
- Ensure all RTL files are present in `rtl/` subdirectories
- Check that PicoRV32 was downloaded: `rtl/core/picorv32.v`
- Verify constraints files exist in `constraints/`

---

## Files Created

**Development Environment**:
- `shell.nix` - NixOS development environment
- `docs/toolchain_install.md` - Installation guide
- `scripts/quickstart.sh` - Quick start script

**RTL** (7 modules, 4,062 lines):
- `rtl/gpu/gpu_accelerator.v` - GPU with AXI-Lite interface
- `rtl/interconnect/mem_interconnect.v` - Memory bus
- `rtl/peripherals/vga_controller.v` - VGA timing
- `rtl/peripherals/dual_port_ram.v` - Frame buffer
- `rtl/peripherals/block_ram.v` - Instruction/data memory
- `rtl/top/riscv_gpu_soc.v` - Top-level integration
- `rtl/core/picorv32.v` - RISC-V processor

**Firmware**:
- `firmware/linker.ld` - Linker script
- `firmware/bootloader/start.S` - Startup code
- `firmware/drivers/gpu_driver.[ch]` - GPU API
- `firmware/examples/test_pattern.c` - Demo program
- `firmware/Makefile` - Build system

**Build System**:
- `scripts/vivado_build.tcl` - Vivado synthesis script
- `scripts/build_fpga.sh` - Build wrapper
- `constraints/timing/timing.xdc` - Timing constraints
- `constraints/pins/pynq_z2_pins.xdc` - Pin assignments

---

## Next Actions

1. **Wait for Nix build** to complete (check terminal output)
2. **Run `nix-shell`** to enter development environment
3. **Build firmware**: `cd firmware && make all`
4. **Optionally simulate**: `cd sim/system && make sim`
5. **Synthesize for FPGA** (if Vivado is available)
6. **Program PYNQ-Z2** and test

---

For detailed information, see:
- `docs/getting_started.md` - Complete setup guide
- `docs/architecture.md` - System architecture
- `docs/gpu_programming_guide.md` - GPU API reference
- Walkthrough artifact - Implementation summary
