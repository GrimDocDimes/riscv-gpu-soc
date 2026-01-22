# Timing Constraints for PYNQ-Z2
# RISC-V + GPU Accelerator SoC

# Input clock - 125 MHz differential clock
create_clock -period 8.000 -name clk_125mhz [get_ports clk_125mhz_p]

# Generated clocks (will be created by clock wizard/MMCM)
# System clock - 50 MHz
create_generated_clock -name clk_sys -source [get_pins clk_wiz/clk_in1] \
    -divide_by 5 -multiply_by 2 [get_pins clk_wiz/clk_out1]

# Pixel clock - 25.175 MHz for VGA 640x480@60Hz
create_generated_clock -name clk_pixel -source [get_pins clk_wiz/clk_in1] \
    -divide_by 248 -multiply_by 50 [get_pins clk_wiz/clk_out2]

# Clock domain crossing constraints
set_clock_groups -asynchronous \
    -group [get_clocks clk_sys] \
    -group [get_clocks clk_pixel]

# Input delay constraints (if using external inputs)
set_input_delay -clock clk_sys -min 0.0 [get_ports rst_n]
set_input_delay -clock clk_sys -max 2.0 [get_ports rst_n]

# Output delay constraints for VGA/HDMI
set_output_delay -clock clk_pixel -min -1.0 [get_ports vga_*]
set_output_delay -clock clk_pixel -max 1.0 [get_ports vga_*]

# False paths
set_false_path -from [get_ports rst_n]
set_false_path -to [get_ports led*]

# BRAM constraints
set_max_delay -from [get_cells -hierarchical -filter {NAME =~ *frame_buffer*}] \
    -to [get_cells -hierarchical -filter {NAME =~ *vga_controller*}] 10.0
