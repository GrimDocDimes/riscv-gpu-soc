# RISC-V + GPU Accelerator SoC

[![Status](https://img.shields.io/badge/Status-Fully_Verified_%26_Tested-brightgreen)](#)
[![Target](https://img.shields.io/badge/Target-PYNQ--Z2_%28XC7Z020%29-blue)](#)

A 32-bit RISC-V soft processor (PicoRV32) integrated with a custom AXI-Lite 2D GPU accelerator, dual-port BRAM frame buffer, and HDMI/VGA output controller for real-time graphics rendering on FPGA.

---

## 🌟 Architecture & Features

* **CPU Core**: PicoRV32 (RV32I RISC-V ISA) operating at 50 MHz
* **GPU Accelerator**: Custom 2D hardware engine supporting:
  * Single pixel draw (`CMD_PIXEL`)
  * Fast Bresenham line drawing algorithm (`CMD_LINE`)
  * Row-by-row rectangle filling (`CMD_RECT`)
  * Full frame buffer clear (`CMD_CLEAR`)
* **Frame Buffer**: 640×480 Dual-Port Block RAM (Port A: GPU Write @ 50 MHz, Port B: Display Read @ 25 MHz)
* **Video Output**: 640×480 @ 60Hz 8-bit RGB332 output serialized via TMDS encoders (`rgb2tmds`) over differential HDMI outputs
* **Bus Interconnect**: Custom memory interconnect mapping IMEM (`0x0000_0000`), DMEM (`0x0000_8000`), and GPU AXI-Lite registers (`0x1000_0000`)

---

## 🗺️ Memory & Register Map

### System Memory Map
| Address Range | Component | Description |
|---|---|---|
| `0x0000_0000 - 0x0000_7FFF` | **Instruction RAM (IMEM)** | 32 KB BRAM (Firmware Code) |
| `0x0000_8000 - 0x0000_FFFF` | **Data RAM (DMEM)** | 32 KB BRAM (Stack & Data) |
| `0x1000_0000 - 0x1000_00FF` | **GPU Registers** | AXI-Lite Peripheral Controls |

### GPU Register Offsets (`0x1000_0000 + Offset`)
| Offset | Register | Access | Description |
|---|---|---|---|
| `0x00` | `CTRL` | RW | Control Register |
| `0x04` | `STATUS` | RO | Bit 0: `busy` flag |
| `0x08` | `CMD` | WO | `1`: Pixel, `2`: Line, `3`: Rect, `4`: Clear |
| `0x0C` / `0x10` | `X0` / `Y0` | RW | Start coordinate $(X_0, Y_0)$ |
| `0x14` / `0x18` | `X1` / `Y1` | RW | End coordinate $(X_1, Y_1)$ |
| `0x1C` | `COLOR` | RW | 8-bit RGB332 color |
| `0x20` / `0x24` | `WIDTH` / `HEIGHT` | RW | Rectangle dimensions |

---

## 🚀 Quick Start & Development Environment

### Method 1: Using Nix Shell (Recommended)
If you have [Nix](https://nixos.org/) installed, enter the reproducible development environment with the pre-configured RISC-V toolchain, GNU Make, and utilities:

```bash
git clone https://github.com/GrimDocDimes/riscv-gpu-soc.git
cd riscv-gpu-soc

# Enter the nix development environment
nix-shell
```

Inside `nix-shell`, `riscv32-none-elf-gcc` and build tools are automatically initialized and ready to use.

### Method 2: Manual Prerequisites
Ensure the following tools are available on your system:
* **RISC-V Toolchain**: `riscv32-none-elf-gcc` or `riscv32-unknown-elf-gcc`
* **Simulation**: `iverilog` (Icarus Verilog >= 11.0) and `gtkwave`
* **FPGA Tools**: Xilinx Vivado (2019.2 / 2020.2 or newer)

---

## 🛠️ Build & Verification Instructions

### 1. Build Firmware
Compile the C firmware demo into RISC-V machine hex format:
```bash
cd firmware
make all
cd ..
```
*Outputs*: `firmware/build/firmware.elf`, `firmware.bin`, and `firmware.hex`

### 2. Run Unit Tests
Run the self-checking unit test suite for hardware modules:
```bash
cd sim/unit
make test
cd ../..
```
*Verifies*: AXI-Lite register R/W, GPU drawing routines, Memory Interconnect address decoding, and VGA 640x480 timing parameters.

### 3. Run Full System Simulation
Execute top-level SoC simulation with RISC-V firmware driving the GPU:
```bash
cd sim/system
make sim
cd ../..
```
*Outputs*: Waveform file `sim/system/tb_riscv_gpu_soc.vcd`. View waveforms with `gtkwave sim/system/tb_riscv_gpu_soc.vcd`.

---

## ⚡ FPGA Synthesis & Deployment (PYNQ-Z2)

### 1. Synthesize & Generate Bitstream
Source your Vivado settings and run the build script:
```bash
# Source Vivado settings script
source /path/to/Xilinx/Vivado/<version>/settings64.sh

# Run synthesis, placement, routing, and bitstream generation
./scripts/build_fpga.sh
```
*Bitstream Output*: `build/riscv_gpu_soc.bit` (Vivado timing sign-off: **WNS = +7.474 ns**, **WHS = +0.055 ns**, 0 unrouted nets).

### 2. Program PYNQ-Z2 Board
Transfer the bitstream to your PYNQ-Z2 board over SSH and load the overlay:
```bash
# Copy bitstream to PYNQ-Z2
scp build/riscv_gpu_soc.bit xilinx@<pynq-ip>:~/

# SSH into PYNQ and program overlay via Python
ssh xilinx@<pynq-ip>
sudo python3 -c "from pynq import Overlay; Overlay('riscv_gpu_soc.bit')"
```

Connect an HDMI monitor to the PYNQ-Z2 **HDMI OUT** port to view the live hardware-accelerated test pattern!

---

## 📁 Repository Structure

```
riscv-gpu-soc/
├── rtl/                    # Synthesizable Verilog HDL sources
│   ├── core/              # RISC-V soft core (PicoRV32)
│   ├── gpu/               # Custom GPU 2D graphics accelerator
│   ├── interconnect/      # Memory interconnect & AXI-Lite bridge
│   ├── peripherals/       # Dual-port BRAM & VGA controller
│   ├── hdmi/              # TMDS 8b/10b encoder & serializer
│   └── top/               # Top-level SoC wrapper (`riscv_gpu_soc.v`)
├── firmware/              # RISC-V C software stack & bootloader
│   ├── drivers/           # GPU hardware driver (`gpu_driver.h`)
│   └── examples/          # Hardware rendering demo (`test_pattern.c`)
├── sim/                   # Testbenches & simulation files
│   ├── unit/              # Self-checking unit tests
│   └── system/            # Full-system co-simulation
├── constraints/           # Vivado timing XDC & PYNQ-Z2 pin assignments
├── scripts/               # Vivado build TCL scripts & quickstart
└── shell.nix              # Reproducible Nix environment configuration
```

---

## 📄 License

Distributed under the [MIT License](LICENSE).
