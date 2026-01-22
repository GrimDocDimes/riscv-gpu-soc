# Getting Started with RISC-V + GPU Accelerator on PYNQ-Z2

This guide will walk you through setting up and running the RISC-V + GPU Accelerator SoC on your PYNQ-Z2 board.

## Prerequisites

### Hardware
- PYNQ-Z2 board
- Micro-USB cable (for programming and UART)
- HDMI cable and monitor (for display output)
- Power supply (5V, 2.5A)

### Software
1. **Xilinx Vivado** (2018.2 or later)
   ```bash
   # Source Vivado settings
   source /tools/Xilinx/Vivado/2020.2/settings64.sh
   ```

2. **RISC-V GCC Toolchain**
   ```bash
   # Check if installed
   riscv32-unknown-elf-gcc --version
   
   # If not installed, download from:
   # https://github.com/riscv-collab/riscv-gnu-toolchain
   ```

3. **Icarus Verilog** (for simulation)
   ```bash
   sudo apt-get install iverilog gtkwave
   ```

## Step 1: Clone and Setup Project

```bash
cd /home/jhush/riscvgpuacc

# Download PicoRV32 core (if not already done)
./scripts/download_picorv32.sh
```

## Step 2: Simulate the Design (Optional)

Before synthesizing for FPGA, you can simulate the design:

```bash
cd sim/system
make sim

# View waveforms
make view
```

## Step 3: Build Firmware

```bash
cd firmware

# Build the test pattern example
make all

# Output files will be in build/:
# - firmware.elf (ELF executable)
# - firmware.bin (binary)
# - firmware.hex (hex format for memory initialization)
```

## Step 4: Synthesize for FPGA

```bash
cd /home/jhush/riscvgpuacc

# Run Vivado synthesis and implementation
./scripts/build_fpga.sh
```

This will:
1. Create Vivado project
2. Add all RTL sources
3. Generate clock wizard IP
4. Run synthesis
5. Run implementation
6. Generate bitstream

The bitstream will be at: `build/riscv_gpu_soc.bit`

**Expected build time**: 10-20 minutes depending on your machine.

## Step 5: Program the PYNQ-Z2

### Method 1: Using Vivado Hardware Manager

1. Connect PYNQ-Z2 via USB
2. Power on the board
3. Open Vivado Hardware Manager:
   ```bash
   vivado -mode gui
   ```
4. Open Hardware Manager → Open Target → Auto Connect
5. Program Device → Select `build/riscv_gpu_soc.bit`

### Method 2: Using PYNQ Python (if PYNQ OS is installed)

```bash
# Copy bitstream to PYNQ board
scp build/riscv_gpu_soc.bit xilinx@pynq:~/

# SSH to PYNQ
ssh xilinx@pynq  # password: xilinx

# Load bitstream
sudo python3 -c "from pynq import Overlay; ol = Overlay('riscv_gpu_soc.bit')"
```

## Step 6: View Output

1. Connect HDMI cable from PYNQ-Z2 to your monitor
2. Power on the board
3. You should see the test pattern:
   - White border around the screen
   - Three colored rectangles (red, green, blue)
   - Diagonal yellow and cyan lines

## Troubleshooting

### No Display Output
- Check HDMI cable connection
- Verify monitor supports 640×480 or 720p resolution
- Check that bitstream programmed successfully
- Verify clock constraints in `constraints/timing/timing.xdc`

### Synthesis Errors
- Ensure all RTL files are present
- Check that PicoRV32 was downloaded successfully
- Verify Vivado version compatibility

### Firmware Build Errors
- Check RISC-V toolchain installation
- Verify `riscv32-unknown-elf-gcc` is in PATH
- Check linker script exists

## Next Steps

Once you have the basic system running:

1. **Modify the test pattern** - Edit `firmware/examples/test_pattern.c`
2. **Create new graphics demos** - Use the GPU API in `firmware/drivers/gpu_driver.h`
3. **Enhance the GPU** - Add new commands like circles, sprites, etc.
4. **Optimize performance** - Profile and optimize critical paths
5. **Add peripherals** - Integrate UART, SPI, or other interfaces

## Useful Commands

```bash
# Clean build files
cd sim/system && make clean
cd firmware && make clean
rm -rf scripts/vivado_project build/

# Rebuild everything
./scripts/download_picorv32.sh
cd firmware && make all
cd .. && ./scripts/build_fpga.sh

# View synthesis reports
cat scripts/vivado_project/utilization_synth.rpt
cat scripts/vivado_project/timing_summary.rpt
```

## Resources

- [PicoRV32 Documentation](https://github.com/YosysHQ/picorv32)
- [PYNQ-Z2 Documentation](http://www.pynq.io/board.html)
- [Vivado User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug835-vivado-tcl-commands.pdf)
- Project Documentation: `docs/`

## Support

For issues or questions:
1. Check `docs/architecture.md` for system details
2. Review `docs/gpu_programming_guide.md` for API usage
3. Check simulation waveforms for debugging
