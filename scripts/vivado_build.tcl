# Vivado Build Script for PYNQ-Z2
# RISC-V + GPU Accelerator SoC

# Project settings
set project_name "riscv_gpu_soc"
set project_dir "./vivado_project"
set top_module "riscv_gpu_soc"

# PYNQ-Z2 board part
set board_part "tul.com.tw:pynq-z2:part0:1.0"
set fpga_part "xc7z020clg400-1"

# Create project
create_project $project_name $project_dir -part $fpga_part -force
set_property board_part $board_part [current_project]

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add source files
puts "Adding RTL source files..."

# Add RTL files
add_files -norecurse [glob ../rtl/core/*.v]
add_files -norecurse [glob ../rtl/gpu/*.v]
add_files -norecurse [glob ../rtl/peripherals/*.v]
add_files -norecurse [glob ../rtl/interconnect/*.v]
add_files -norecurse [glob ../rtl/top/*.v]

# Add constraint files
puts "Adding constraint files..."
add_files -fileset constrs_1 -norecurse ../constraints/timing/timing.xdc
add_files -fileset constrs_1 -norecurse ../constraints/pins/pynq_z2_pins.xdc

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Create IP cores (Clock Wizard for clock generation)
puts "Creating IP cores..."

# Clock Wizard for generating system and pixel clocks
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {125.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {25.175} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.NUM_OUT_PORTS {2} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.RESET_PORT {resetn} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
create_ip_run [get_ips clk_wiz_0]

# Synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1

# Report utilization
report_utilization -file $project_dir/utilization_synth.rpt

# Implementation
puts "Running implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1

# Report timing and utilization
report_timing_summary -file $project_dir/timing_summary.rpt
report_utilization -file $project_dir/utilization_impl.rpt
report_power -file $project_dir/power.rpt

# Generate bitstream
puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Copy bitstream to output directory
file mkdir ../build
file copy -force $project_dir/$project_name.runs/impl_1/$top_module.bit ../build/$project_name.bit
file copy -force $project_dir/$project_name.runs/impl_1/$top_module.ltx ../build/$project_name.ltx

puts "Build complete! Bitstream: ../build/$project_name.bit"
