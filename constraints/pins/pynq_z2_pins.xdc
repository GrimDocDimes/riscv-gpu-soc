# Pin Constraints for PYNQ-Z2
# RISC-V + GPU Accelerator SoC

# Clock input - 125 MHz differential
# Note: PYNQ-Z2 H16/H17 are on Bank 35 (High Range), so LVDS is not supported.
# We use TMDS_33 which is compatible with 3.3V HR banks.
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports clk_125mhz_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports clk_125mhz_n]

# Reset button (BTN0)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports rst_n]

# LEDs for debugging
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

# HDMI output (mapped from VGA signals)
# Note: This requires a TMDS encoder in RTL for real HDMI, 
# but we'll map the pins to avoid "no object" errors.
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports vga_hsync]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports vga_vsync]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {vga_rgb[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {vga_rgb[1]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {vga_rgb[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {vga_rgb[3]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD TMDS_33} [get_ports {vga_rgb[4]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD TMDS_33} [get_ports {vga_rgb[5]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports {vga_rgb[6]}]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports {vga_rgb[7]}]

# Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
