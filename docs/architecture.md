# RISC-V + GPU Accelerator SoC - Architecture Specification

## System Overview

This document describes the architecture of the RISC-V + GPU Accelerator SoC, a system designed to demonstrate real-time hardware-accelerated graphics rendering on FPGA.

## Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Top-Level SoC                          │
│                                                             │
│  ┌──────────────┐         ┌─────────────────────────────┐  │
│  │              │         │    AXI-Lite Interconnect    │  │
│  │  PicoRV32    │◄───────►│                             │  │
│  │   Core       │         │  ┌────────┐  ┌───────────┐  │  │
│  │  (RV32I)     │         │  │  GPU   │  │    VGA    │  │  │
│  │              │         │  │  Accel │  │   Ctrl    │  │  │
│  └──────────────┘         │  └────────┘  └───────────┘  │  │
│         │                 │       │            │         │  │
│         │                 └───────┼────────────┼─────────┘  │
│         │                         │            │            │
│         ▼                         ▼            │            │
│  ┌──────────────┐         ┌─────────────┐     │            │
│  │ Instruction  │         │   Frame     │     │            │
│  │   Memory     │         │   Buffer    │     │            │
│  │   (BRAM)     │         │   (BRAM)    │     │            │
│  └──────────────┘         └─────────────┘     │            │
│                                                │            │
└────────────────────────────────────────────────┼────────────┘
                                                 │
                                                 ▼
                                          ┌─────────────┐
                                          │ VGA Output  │
                                          │ 640×480@60Hz│
                                          └─────────────┘
```

## Component Specifications

### 1. PicoRV32 Core
- **ISA**: RV32I (32-bit RISC-V base integer instruction set)
- **Clock**: 25-50 MHz (configurable)
- **Memory Interface**: Native memory interface (converted to AXI-Lite)
- **Features**: 
  - Single-cycle execution for most instructions
  - Compact design (~1000 LUTs)
  - Configurable register file

### 2. GPU Accelerator
- **Purpose**: Hardware acceleration for 2D graphics primitives
- **Supported Operations**:
  - Pixel write (single/multiple)
  - Line drawing (Bresenham's algorithm)
  - Rectangle fill
  - Color palette management
- **Interface**: AXI-Lite slave
- **Registers**: Memory-mapped control/status registers
- **Performance**: 1 pixel/cycle for sequential operations

### 3. Frame Buffer
- **Size**: 640×480 pixels
- **Color Depth**: 8-bit (256 colors, palette-based)
- **Memory**: Dual-port BRAM
  - Port A: GPU accelerator write access
  - Port B: VGA controller read access
- **Total Size**: 307,200 bytes (~300 KB)

### 4. VGA Controller
- **Resolution**: 640×480 @ 60Hz
- **Pixel Clock**: 25.175 MHz
- **Color Output**: 8-bit RGB (3:3:2 or palette lookup)
- **Timing**: Standard VGA timing
  - H-sync: 31.5 kHz
  - V-sync: 60 Hz

### 5. AXI-Lite Interconnect
- **Protocol**: AXI4-Lite
- **Data Width**: 32-bit
- **Address Width**: 32-bit
- **Masters**: PicoRV32 core
- **Slaves**: GPU accelerator, VGA controller (config registers)

## Memory Map

```
0x0000_0000 - 0x0000_FFFF : Instruction Memory (64 KB BRAM)
0x0001_0000 - 0x0001_FFFF : Data Memory (64 KB BRAM)
0x1000_0000 - 0x1000_00FF : GPU Accelerator Registers
0x1000_0100 - 0x1000_01FF : VGA Controller Registers
0x2000_0000 - 0x204AFFF   : Frame Buffer (307,200 bytes)
```

### GPU Accelerator Register Map

| Offset | Name          | Access | Description                    |
|--------|---------------|--------|--------------------------------|
| 0x00   | CTRL          | RW     | Control register               |
| 0x04   | STATUS        | RO     | Status register                |
| 0x08   | CMD           | WO     | Command register               |
| 0x0C   | X0            | RW     | X coordinate 0                 |
| 0x10   | Y0            | RW     | Y coordinate 0                 |
| 0x14   | X1            | RW     | X coordinate 1                 |
| 0x18   | Y1            | RW     | Y coordinate 1                 |
| 0x1C   | COLOR         | RW     | Draw color (8-bit)             |
| 0x20   | WIDTH         | RW     | Rectangle width                |
| 0x24   | HEIGHT        | RW     | Rectangle height               |

### GPU Commands

| Command | Value | Description                    |
|---------|-------|--------------------------------|
| NOP     | 0x00  | No operation                   |
| PIXEL   | 0x01  | Draw pixel at (X0, Y0)         |
| LINE    | 0x02  | Draw line from (X0,Y0) to (X1,Y1) |
| RECT    | 0x03  | Fill rectangle                 |
| CLEAR   | 0x04  | Clear frame buffer             |

## Timing and Performance

### Clock Domains
- **System Clock**: 50 MHz (RISC-V, GPU, memory)
- **Pixel Clock**: 25.175 MHz (VGA controller)

### Performance Targets
- **Line Drawing**: ~1 pixel/cycle (25-50 Mpixels/sec)
- **Rectangle Fill**: ~1 pixel/cycle
- **Frame Clear**: ~12 ms @ 25 MHz (full 640×480 frame)

## Power and Resource Estimates

### FPGA Resource Usage (Estimated)
- **LUTs**: ~3,000-5,000
- **Flip-Flops**: ~2,000-3,000
- **BRAM**: ~40-50 blocks (18Kb each)
- **DSP**: 0-2 (optional for multipliers)

### Target Devices
- Xilinx Artix-7 (XC7A35T or larger)
- Xilinx Spartan-7 (XC7S50 or larger)
- Intel Cyclone V
- Lattice ECP5

## Design Considerations

### 1. Memory Bandwidth
- Frame buffer requires dual-port access
- GPU writes while VGA reads simultaneously
- No arbitration needed due to dual-port BRAM

### 2. Clock Domain Crossing
- System clock (50 MHz) to pixel clock (25.175 MHz)
- Use asynchronous FIFO or dual-clock BRAM

### 3. Reset Strategy
- Synchronous reset for all logic
- Power-on reset generation
- Software reset capability via control registers

### 4. Extensibility
- Modular design allows easy addition of new GPU commands
- AXI-Lite interface enables adding more peripherals
- Parameterized design for different resolutions/color depths
