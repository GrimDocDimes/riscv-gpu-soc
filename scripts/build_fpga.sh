#!/bin/bash
# Build script for FPGA synthesis on PYNQ-Z2
# Uses Xilinx Vivado

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
BUILD_DIR="${PROJECT_ROOT}/build"

echo "=== RISC-V + GPU Accelerator SoC - FPGA Build Script ==="
echo "Target Board: PYNQ-Z2 (Zynq XC7Z020)"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Check if Vivado is available
if ! command -v vivado &> /dev/null; then
    echo "ERROR: Vivado not found in PATH"
    echo "Please source Vivado settings:"
    echo "  source /tools/Xilinx/Vivado/2020.2/settings64.sh"
    exit 1
fi

echo "Vivado found: $(which vivado)"
echo ""

# Create build directory
mkdir -p "${BUILD_DIR}"

# Run Vivado build
cd "${SCRIPTS_DIR}"
echo "Running Vivado build script..."
vivado -mode batch -source vivado_build.tcl -notrace

echo ""
echo "Build complete!"
echo "Bitstream: ${BUILD_DIR}/riscv_gpu_soc.bit"
echo ""
echo "To program PYNQ-Z2:"
echo "  1. Copy bitstream to PYNQ board"
echo "  2. Use: sudo python3 -c 'from pynq import Overlay; ol = Overlay(\"riscv_gpu_soc.bit\")'"

