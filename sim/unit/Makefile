# Makefile for Unit Tests
IVERILOG = iverilog
VVP      = vvp

RTL_DIR = ../../rtl

.PHONY: all test test_gpu test_mem test_vga clean

all: test

test: test_gpu test_mem test_vga

test_gpu: tb_gpu_accelerator.vvp
	@echo "--- Running GPU Accelerator Unit Test ---"
	$(VVP) tb_gpu_accelerator.vvp

tb_gpu_accelerator.vvp: tb_gpu_accelerator.v $(RTL_DIR)/gpu/gpu_accelerator.v
	$(IVERILOG) -g2012 -o tb_gpu_accelerator.vvp tb_gpu_accelerator.v $(RTL_DIR)/gpu/gpu_accelerator.v

test_mem: tb_mem_interconnect.vvp
	@echo "--- Running Memory Interconnect Unit Test ---"
	$(VVP) tb_mem_interconnect.vvp

tb_mem_interconnect.vvp: tb_mem_interconnect.v $(RTL_DIR)/interconnect/mem_interconnect.v
	$(IVERILOG) -g2012 -o tb_mem_interconnect.vvp tb_mem_interconnect.v $(RTL_DIR)/interconnect/mem_interconnect.v

test_vga: tb_vga_controller.vvp
	@echo "--- Running VGA Controller Unit Test ---"
	$(VVP) tb_vga_controller.vvp

tb_vga_controller.vvp: tb_vga_controller.v $(RTL_DIR)/peripherals/vga_controller.v
	$(IVERILOG) -g2012 -o tb_vga_controller.vvp tb_vga_controller.v $(RTL_DIR)/peripherals/vga_controller.v

clean:
	rm -f *.vvp *.vcd
