// Testbench for RISC-V GPU SoC
// Targets riscv_gpu_soc_sim (simulation wrapper — no Xilinx primitives)
//
// Features:
//   - Correct port mapping (flat clocks, flat VGA outputs, led[3:0])
//   - Firmware loaded via $readmemh into instruction memory BRAM
//   - VCD waveform dump for GTKWave inspection
//   - VSync edge detector to count completed frames
//   - Optional: frame buffer PPM dump via $fwrite for visual verification

`timescale 1ns/1ps
`define SIMULATION

module tb_riscv_gpu_soc;

    // =====================================================================
    // DUT Clock & Reset
    // =====================================================================
    reg clk_50mhz;
    reg clk_25mhz;
    reg rst_n;

    // =====================================================================
    // DUT Output Signals
    // =====================================================================
    wire        vga_hsync;
    wire        vga_vsync;
    wire        vga_active;
    wire [7:0]  vga_rgb;
    wire [3:0]  led;

    // =====================================================================
    // DUT Instantiation (simulation wrapper — no Xilinx IP)
    // =====================================================================
    riscv_gpu_soc_sim #(
        .FRAME_WIDTH  (640),
        .FRAME_HEIGHT (480),
        .COLOR_DEPTH  (8)
    ) dut (
        .clk_50mhz  (clk_50mhz),
        .clk_25mhz  (clk_25mhz),
        .rst_n      (rst_n),
        .vga_hsync  (vga_hsync),
        .vga_vsync  (vga_vsync),
        .vga_active (vga_active),
        .vga_rgb    (vga_rgb),
        .led        (led)
    );

    // =====================================================================
    // Clock Generation
    //   50 MHz → 20 ns period
    //   25 MHz → 40 ns period (phase-aligned to 50 MHz)
    // =====================================================================
    initial clk_50mhz = 1'b0;
    always #10 clk_50mhz = ~clk_50mhz;   // 50 MHz

    initial clk_25mhz = 1'b0;
    always #20 clk_25mhz = ~clk_25mhz;   // 25 MHz

    // =====================================================================
    // Frame Counter (counts vsync falling edges = completed frames)
    // =====================================================================
    integer frame_count;
    reg     vsync_prev;

    always @(posedge clk_25mhz) begin
        vsync_prev <= vga_vsync;
        if (vsync_prev && !vga_vsync) begin
            frame_count <= frame_count + 1;
            $display("[TB] Frame %0d completed at time %0t ns", frame_count, $time);
        end
    end

    // =====================================================================
    // Main Simulation Sequence
    // =====================================================================
    initial begin
        // VCD dump for waveform viewer
        $dumpfile("tb_riscv_gpu_soc.vcd");
        $dumpvars(0, tb_riscv_gpu_soc);

        // Initialize
        rst_n       = 1'b0;
        frame_count = 0;
        vsync_prev  = 1'b0;

        // Load firmware into instruction memory BRAM
        // Adjust path as needed relative to simulation working directory
        $readmemh("../../firmware/build/firmware.hex", dut.imem.ram);
        $display("[TB] Firmware loaded into instruction memory.");

        // Hold reset for 10 system clock cycles
        repeat (10) @(posedge clk_50mhz);
        @(negedge clk_50mhz);
        rst_n = 1'b1;
        $display("[TB] Reset released — CPU running.");

        // ----------------------------------------------------------------
        // Run simulation:
        //   One full VGA frame = 800 × 525 = 420,000 pixel clocks @ 25 MHz
        //   = 420,000 × 40 ns = 16.8 ms
        //   Run for 3 frames (~50 ms) to observe GPU rendering.
        //   At 25 MHz sim speed this is ~50,400,000 ns.
        // ----------------------------------------------------------------
        #50_000_000;   // 50 ms of simulated time

        $display("[TB] Simulation complete. Total frames rendered: %0d", frame_count);
        $finish;
    end

    // =====================================================================
    // Simulation Timeout Safety
    // =====================================================================
    initial begin
        #200_000_000;   // 200 ms hard timeout
        $display("[TB] ERROR: Simulation timeout! Check for FSM deadlocks.");
        $finish;
    end

    // =====================================================================
    // GPU Activity Monitor (watch frame buffer writes)
    // =====================================================================
    integer gpu_write_count;
    initial gpu_write_count = 0;

    always @(posedge clk_50mhz) begin
        if (dut.fb_we_gpu) begin
            gpu_write_count <= gpu_write_count + 1;
        end
    end

    // Print GPU write stats every 1000 GPU pixel writes
    always @(posedge clk_50mhz) begin
        if (gpu_write_count > 0 && (gpu_write_count % 1000 == 0)) begin
            $display("[TB] GPU has written %0d pixels (t=%0t ns)", gpu_write_count, $time);
        end
    end

    // =====================================================================
    // LED Monitor
    // =====================================================================
    always @(led) begin
        $display("[TB] LED state changed: %b (mem_valid=%b mem_ready=%b fb_we=%b hsync=%b)",
                 led, led[3], led[2], led[1], led[0]);
    end

endmodule
