# Makefile for simulation
# Uses Icarus Verilog by default

IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

RTL_DIR = ../../rtl
SRC_FILES = $(RTL_DIR)/gpu/gpu_accelerator.v \
            $(RTL_DIR)/peripherals/vga_controller.v \
            $(RTL_DIR)/top/riscv_gpu_soc.v

TB_TOP = tb_riscv_gpu_soc
TB_FILE = $(TB_TOP).v

VVP_FILE = $(TB_TOP).vvp
VCD_FILE = $(TB_TOP).vcd

.PHONY: all sim view clean

all: sim

sim: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

$(VVP_FILE): $(TB_FILE) $(SRC_FILES)
	$(IVERILOG) -o $(VVP_FILE) -s $(TB_TOP) $(TB_FILE) $(SRC_FILES)

view: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE)

clean:
	rm -f $(VVP_FILE) $(VCD_FILE)

help:
	@echo "Simulation Makefile"
	@echo "  make sim   - Run simulation"
	@echo "  make view  - View waveforms in GTKWave"
	@echo "  make clean - Clean build files"
