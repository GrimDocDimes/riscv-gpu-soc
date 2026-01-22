# RISC-V + GPU Accelerator SoC

**Status:** 🟢 In Development

A RISC-V soft processor integrated with a custom GPU-style accelerator on FPGA for real-time hardware-based graphics rendering.

## 🎯 Project Goal

Demonstrate real-time hardware-based graphics rendering controlled by a soft RISC-V processor on FPGA, featuring:
- **RISC-V Core**: PicoRV32 soft processor
- **GPU Accelerator**: Custom 2D graphics accelerator for line drawing and pixel operations
- **VGA Output**: 640×480 resolution display
- **AXI-Lite Interface**: Memory-mapped register control for hardware acceleration

## 📁 Project Structure

```
riscvgpuacc/
├── rtl/                    # RTL design files
│   ├── core/              # RISC-V core (PicoRV32)
│   ├── gpu/               # GPU accelerator modules
│   ├── peripherals/       # VGA controller, memory controller
│   ├── interconnect/      # AXI-Lite bus and bridges
│   └── top/               # Top-level integration
├── firmware/              # RISC-V firmware
│   ├── bootloader/        # Boot code
│   ├── drivers/           # GPU driver library
│   └── examples/          # Demo applications
├── sim/                   # Simulation testbenches
│   ├── unit/             # Unit tests
│   └── system/           # System-level tests
├── constraints/           # FPGA constraints
│   ├── timing/           # Timing constraints
│   └── pins/             # Pin assignments
├── scripts/              # Build and automation scripts
├── docs/                 # Documentation
└── tools/                # Development tools
```

## 🚀 Quick Start

### Prerequisites
- **FPGA Board**: PYNQ-Z2 (Zynq XC7Z020)
- **Xilinx Vivado** 2018.2 or later
- **RISC-V GCC toolchain** (`riscv32-unknown-elf-gcc`)
- **Icarus Verilog** or ModelSim (for simulation)
- **Python 3.x** with PYNQ libraries (for deployment)

### Build Instructions
```bash
# Download PicoRV32 core (already done if you ran setup)
./scripts/download_picorv32.sh

# Simulate the design
cd sim/system
make sim

# Build firmware
cd firmware
make all

# Synthesize for FPGA (PYNQ-Z2)
./scripts/build_fpga.sh
```

## 🏗️ Architecture Overview

The system consists of:
1. **PicoRV32 Core** - 32-bit RISC-V processor (RV32I)
2. **GPU Accelerator** - Hardware block for 2D graphics primitives
3. **Frame Buffer** - Dual-port RAM for VGA output
4. **VGA Controller** - 640×480@60Hz video output
5. **AXI-Lite Interconnect** - Memory-mapped peripheral access

## 📋 Development Roadmap

- [x] Project initialization
- [ ] PicoRV32 core integration
- [ ] GPU accelerator design
- [ ] VGA controller implementation
- [ ] AXI-Lite interconnect
- [ ] Firmware development
- [ ] System simulation
- [ ] FPGA implementation

## 📖 Documentation

See the `docs/` directory for detailed documentation:
- Architecture specification
- GPU programming guide
- Memory map
- API reference

## 🔧 Hardware Support

**Target Board**: PYNQ-Z2
- FPGA: Xilinx Zynq XC7Z020-1CLG400C
- HDMI output (native on board)
- 512 MB DDR3 memory
- Dual-core ARM Cortex-A9 (not used in pure RISC-V mode)

See `docs/pynq_z2_config.md` for detailed board configuration.

## 📝 License

MIT License - See LICENSE file for details
