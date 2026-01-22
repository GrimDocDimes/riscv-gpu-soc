{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "riscv-gpu-dev";
  
  buildInputs = with pkgs; [
    # RISC-V toolchain
    pkgsCross.riscv32-embedded.buildPackages.gcc
    pkgsCross.riscv32-embedded.buildPackages.binutils
    
    # Build tools
    gnumake
    
    # Utilities
    curl
    wget
  ];
  
  shellHook = ''
    echo "=== RISC-V + GPU Accelerator Development Environment ==="
    echo ""
    echo "RISC-V Toolchain:"
    riscv32-none-elf-gcc --version 2>/dev/null | head -1 || echo "  Initializing..."
    echo ""
    echo "Available tools:"
    echo "  - riscv32-none-elf-gcc (RISC-V GCC compiler)"
    echo "  - riscv32-none-elf-objcopy, objdump, etc."
    echo "  - make (Build system)"
    echo ""
    echo "Simulation tools (system-installed):"
    echo "  - iverilog: $(which iverilog 2>/dev/null || echo 'not found')"
    echo "  - gtkwave: $(which gtkwave 2>/dev/null || echo 'not found')"
    echo ""
    echo "Quick start:"
    echo "  cd firmware && make all    # Build firmware"
    echo "  cd sim/system && make sim  # Run simulation"
    echo ""
  '';
}
