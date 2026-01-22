# Pin Constraints for PYNQ-Z2
# RISC-V + GPU Accelerator SoC

# Clock input - 125 MHz differential
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVDS} [get_ports clk_125mhz_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVDS} [get_ports clk_125mhz_n]

# Reset button (BTN0)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports rst_n]

# LEDs for debugging
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

# VGA output via Pmod A (if using VGA)
# Pmod A pins: JA1-JA8 (top row: JA1-JA4, bottom row: JA7-JA10)
# VGA pinout: R[3:0], G[3:0], B[3:0], HSYNC, VSYNC

# Option 1: VGA via Pmod A (12-bit color)
# Uncomment if using VGA Pmod adapter
# set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {vga_r[0]}]
# set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {vga_r[1]}]
# set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {vga_r[2]}]
# set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {vga_r[3]}]
# set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {vga_g[0]}]
# set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {vga_g[1]}]
# set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {vga_g[2]}]
# set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {vga_g[3]}]
# set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {vga_b[0]}]
# set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {vga_b[1]}]
# set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {vga_b[2]}]
# set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {vga_b[3]}]
# set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports vga_hsync]
# set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports vga_vsync]

# Option 2: HDMI output (recommended for PYNQ-Z2)
# HDMI TX pins
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[2]}]

# Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
