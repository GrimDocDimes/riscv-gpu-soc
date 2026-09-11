# Makefile for simulation
# Uses Icarus Verilog (iverilog)
#
# Source list uses riscv_gpu_soc_sim.v (not riscv_gpu_soc.v) to avoid
# Xilinx-specific primitives (clk_wiz_0, OSERDESE2, OBUFDS) that cannot
# be elaborated without vendor simulation libraries.

IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

RTL_DIR = ../../rtl

# All synthesizable RTL modules (excluding synthesis-only top-level)
SRC_FILES = \
    $(RTL_DIR)/core/picorv32.v              \
    $(RTL_DIR)/gpu/gpu_accelerator.v        \
    $(RTL_DIR)/interconnect/mem_interconnect.v \
    $(RTL_DIR)/peripherals/vga_controller.v \
    $(RTL_DIR)/peripherals/block_ram.v      \
    $(RTL_DIR)/peripherals/dual_port_ram.v  \
    $(RTL_DIR)/top/riscv_gpu_soc_sim.v

TB_TOP  = tb_riscv_gpu_soc
TB_FILE = $(TB_TOP).v

VVP_FILE = $(TB_TOP).vvp
VCD_FILE = $(TB_TOP).vcd

# iverilog flags:
#   -g2012   : enable SystemVerilog-2012 features (e.g. $clog2, signed)
#   -DSIMULATION : enable `ifdef SIMULATION blocks in RTL
#   -s       : set top-level module
IVFLAGS = -g2012 -DSIMULATION -s $(TB_TOP)

.PHONY: all sim view clean help

all: sim

sim: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

$(VVP_FILE): $(TB_FILE) $(SRC_FILES)
	$(IVERILOG) $(IVFLAGS) -o $(VVP_FILE) $(TB_FILE) $(SRC_FILES)

view: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

clean:
	rm -f $(VVP_FILE) $(VCD_FILE)

help:
	@echo "RISC-V GPU SoC — Simulation Makefile"
	@echo ""
	@echo "  make sim    - Compile and run simulation (generates VCD)"
	@echo "  make view   - Open waveforms in GTKWave"
	@echo "  make clean  - Remove generated files"
	@echo ""
	@echo "Prerequisites:"
	@echo "  iverilog >= 11.0  (install via nix-shell or apt)"
	@echo "  gtkwave           (for 'make view')"
	@echo ""
	@echo "Note: Firmware must be built first:"
	@echo "  cd ../../firmware && make all"
