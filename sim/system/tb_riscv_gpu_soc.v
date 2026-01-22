// Testbench for RISC-V GPU SoC
// Basic simulation to verify module connectivity

`timescale 1ns/1ps

module tb_riscv_gpu_soc;

    // Clock generation
    reg clk_50mhz;
    reg clk_25mhz;
    reg rst_n;
    
    // VGA outputs
    wire vga_hsync;
    wire vga_vsync;
    wire [7:0] vga_rgb;
    wire [7:0] debug_leds;
    
    // Instantiate DUT
    riscv_gpu_soc #(
        .FRAME_WIDTH(640),
        .FRAME_HEIGHT(480),
        .COLOR_DEPTH(8)
    ) dut (
        .clk_50mhz(clk_50mhz),
        .clk_25mhz(clk_25mhz),
        .rst_n(rst_n),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_rgb(vga_rgb),
        .debug_leds(debug_leds)
    );
    
    // 50 MHz clock (20ns period)
    initial begin
        clk_50mhz = 0;
        forever #10 clk_50mhz = ~clk_50mhz;
    end
    
    // 25 MHz clock (40ns period)
    initial begin
        clk_25mhz = 0;
        forever #20 clk_25mhz = ~clk_25mhz;
    end
    
    // Test sequence
    initial begin
        $dumpfile("tb_riscv_gpu_soc.vcd");
        $dumpvars(0, tb_riscv_gpu_soc);
        
        // Reset
        rst_n = 0;
        #100;
        rst_n = 1;
        
        // Run simulation
        #10000;
        
        $display("Simulation completed");
        $finish;
    end
    
    // Monitor VGA sync signals
    initial begin
        $monitor("Time=%0t hsync=%b vsync=%b rgb=%h", 
                 $time, vga_hsync, vga_vsync, vga_rgb);
    end

endmodule
