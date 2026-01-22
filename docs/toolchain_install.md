# RISC-V Toolchain Installation Guide

## For NixOS (Recommended)

We've created a `shell.nix` file for easy setup:

```bash
# Enter the development environment
nix-shell

# The RISC-V toolchain will be automatically available
riscv32-none-elf-gcc --version
```

The shell environment includes:
- RISC-V GCC cross-compiler (`riscv32-none-elf-gcc`)
- Binutils (assembler, linker, objcopy, etc.)
- Icarus Verilog (for simulation)
- GTKWave (for waveform viewing)
- Make and other build tools

## Alternative: Manual Installation

If you prefer not to use Nix, you can install the toolchain manually:

### Option 1: Pre-built Toolchain

```bash
# Download pre-built RISC-V toolchain
cd /tmp
wget https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-3/xpack-riscv-none-elf-gcc-12.2.0-3-linux-x64.tar.gz

# Extract
tar -xzf xpack-riscv-none-elf-gcc-12.2.0-3-linux-x64.tar.gz

# Move to /opt
sudo mv xpack-riscv-none-elf-gcc-12.2.0-3 /opt/riscv

# Add to PATH
echo 'export PATH=/opt/riscv/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify
riscv-none-elf-gcc --version
```

### Option 2: Build from Source

```bash
# Install dependencies
sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
    libtool patchutils bc zlib1g-dev libexpat-dev

# Clone repository
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain

# Configure for RV32I
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32

# Build (takes 30-60 minutes)
make

# Add to PATH
echo 'export PATH=/opt/riscv/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Updating Firmware Makefile

The firmware Makefile needs to be updated for the actual toolchain prefix:

**NixOS**: Change `CROSS_COMPILE = riscv32-unknown-elf-` to `riscv32-none-elf-`  
**Manual install**: Use `riscv-none-elf-` or `riscv32-unknown-elf-` depending on your installation

## Verification

After installation, verify the toolchain:

```bash
# Check compiler
riscv32-none-elf-gcc --version

# Check binutils
riscv32-none-elf-objdump --version
riscv32-none-elf-objcopy --version

# Test compilation
cd firmware
make all
```

## Quick Start with Nix (Easiest)

```bash
cd /home/jhush/riscvgpuacc

# Enter development shell
nix-shell

# Build firmware
cd firmware
make all

# Run simulation
cd ../sim/system
make sim
```

This is the recommended approach for NixOS as it handles all dependencies automatically!
