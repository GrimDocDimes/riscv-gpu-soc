# Pin Constraints for PYNQ-Z2
# RISC-V + GPU Accelerator SoC
# Target: Xilinx Zynq XC7Z020-1CLG400C

# ===========================================================================
# Clock input — 125 MHz differential pair
# PYNQ-Z2: H16/H17 on Bank 35 (High Range).
# Bank 35 is a 3.3V HR bank — use TMDS_33 for differential signaling.
# ===========================================================================
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports clk_125mhz_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports clk_125mhz_n]

# ===========================================================================
# Reset — BTN0 (active-low)
# ===========================================================================
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports rst_n]

# ===========================================================================
# Debug LEDs
# ===========================================================================
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

# ===========================================================================
# HDMI Output — Differential TMDS pairs
# PYNQ-Z2 HDMI TX connector on Bank 35 (3.3V HR)
# Pinout matches Digilent PYNQ-Z2 schematic Rev 1.0
#
# HDMI TX lanes:
#   D2 (Red)   → T.HDMI_TX_2_P / T.HDMI_TX_2_N
#   D1 (Green) → T.HDMI_TX_1_P / T.HDMI_TX_1_N
#   D0 (Blue)  → T.HDMI_TX_0_P / T.HDMI_TX_0_N
#   CLK        → T.HDMI_TX_CLK_P / T.HDMI_TX_CLK_N
#
# IOSTANDARD: TMDS_33 — compatible with HR bank 3.3V I/O for HDMI 1.4
# ===========================================================================

# HDMI TX Clock
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports hdmi_clk_p]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports hdmi_clk_n]

# HDMI TX Channel 0 (Blue)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports hdmi_d0_p]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports hdmi_d0_n]

# HDMI TX Channel 1 (Green)
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports hdmi_d1_p]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports hdmi_d1_n]

# HDMI TX Channel 2 (Red)
set_property -dict {PACKAGE_PIN G19 IOSTANDARD TMDS_33} [get_ports hdmi_d2_p]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD TMDS_33} [get_ports hdmi_d2_n]

# ===========================================================================
# Configuration settings
# ===========================================================================
set_property CFGBVS         VCCO [current_design]
set_property CONFIG_VOLTAGE  3.3  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
