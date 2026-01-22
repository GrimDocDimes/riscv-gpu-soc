# PYNQ-Z2 Board Configuration

## Board Specifications

- **FPGA**: Xilinx Zynq XC7Z020-1CLG400C
- **ARM Cores**: Dual-core ARM Cortex-A9 @ 650 MHz
- **FPGA Fabric**: Artix-7 based programmable logic
- **Memory**: 512 MB DDR3
- **HDMI Output**: Available (can be used instead of VGA)
- **Clock**: 125 MHz differential clock input

## Design Approach Options

### Option 1: Pure FPGA Implementation (Current Plan)
- PicoRV32 in programmable logic
- GPU accelerator in programmable logic
- VGA/HDMI output from PL
- **Pros**: True soft processor implementation, educational
- **Cons**: More complex, requires VGA DAC or HDMI encoder

### Option 2: Hybrid ARM + FPGA
- Use ARM PS for control software
- GPU accelerator in PL
- HDMI output via PS
- **Pros**: Easier development, better performance, native HDMI
- **Cons**: Not pure RISC-V implementation

## Current Configuration: Pure FPGA (Option 1)

We'll implement the original vision with PicoRV32 in the FPGA fabric.

## Pin Assignments for PYNQ-Z2

### HDMI Output (Recommended)
The PYNQ-Z2 has HDMI output which is better than VGA. We can use the HDMI pins:

```
# HDMI TX (Output)
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_d_n[2]}]
```

### Pmod Connectors (for VGA DAC alternative)
If using VGA via Pmod VGA adapter:
- Pmod A or Pmod B can be used with VGA Pmod adapter

### LEDs (for debugging)
```
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
```

### Buttons
```
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports btn[0]]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports btn[1]]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports btn[2]]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports btn[3]]
```

### Switches
```
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports sw[0]]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports sw[1]]
```

## Clock Configuration

- **Input Clock**: 125 MHz differential (H16/H17)
- **System Clock**: 50 MHz (generated via MMCM/PLL)
- **Pixel Clock**: 25.175 MHz for VGA, 74.25 MHz for 720p HDMI

## Memory Resources

The XC7Z020 has:
- **Block RAM**: 140 blocks (36Kb each) = 4.9 Mb total
- **LUTs**: 53,200
- **Flip-Flops**: 106,400
- **DSP Slices**: 220

Our design will use approximately:
- **Frame Buffer**: ~40 BRAM blocks (for 640×480×8-bit)
- **PicoRV32**: ~1,500 LUTs
- **GPU Accelerator**: ~2,000 LUTs
- **VGA/HDMI Controller**: ~500 LUTs
- **Total**: Well within available resources

## Recommended Output: HDMI

For PYNQ-Z2, I recommend using HDMI output instead of VGA because:
1. Native HDMI connector on board
2. Better image quality
3. No need for external DAC
4. Standard 720p (1280×720) or 480p (640×480) support

Would you like to use HDMI output, or stick with VGA via Pmod?
