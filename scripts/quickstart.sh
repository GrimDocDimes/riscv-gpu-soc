#!/bin/bash
# Quick Start Script for RISC-V + GPU Accelerator SoC

set -e

echo "=== RISC-V + GPU Accelerator SoC - Quick Start ==="
echo ""

# Check if in nix-shell
if [ -z "$IN_NIX_SHELL" ]; then
    echo "⚠️  Not in nix-shell environment"
    echo "Please run: nix-shell"
    echo "Then run this script again inside the shell"
    exit 1
fi

echo "✓ NixOS development environment active"
echo ""

# Check toolchain
if ! command -v riscv32-none-elf-gcc &> /dev/null; then
    echo "✗ RISC-V toolchain not found"
    exit 1
fi

echo "✓ RISC-V toolchain found:"
riscv32-none-elf-gcc --version | head -1
echo ""

# Build firmware
echo "Building firmware..."
cd firmware
make clean
make all

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Firmware built successfully!"
    echo ""
    echo "Output files:"
    ls -lh build/
    echo ""
else
    echo "✗ Firmware build failed"
    exit 1
fi

cd ..

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Simulate the design:"
echo "   cd sim/system && make sim"
echo ""
echo "2. Synthesize for FPGA (requires Vivado):"
echo "   source /tools/Xilinx/Vivado/2020.2/settings64.sh"
echo "   ./scripts/build_fpga.sh"
echo ""
echo "3. Program PYNQ-Z2:"
echo "   Copy build/riscv_gpu_soc.bit to PYNQ board"
echo ""
