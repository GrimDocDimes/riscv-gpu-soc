// Self-checking Unit Testbench for VGA Controller
`timescale 1ns/1ps

module tb_vga_controller;

    parameter H_VISIBLE   = 640;
    parameter V_VISIBLE   = 480;
    parameter COLOR_DEPTH = 8;
    localparam FB_ADDR_W  = $clog2(H_VISIBLE * V_VISIBLE);

    reg pclk;
    reg rst_n;

    wire [FB_ADDR_W-1:0] fb_addr;
    reg [COLOR_DEPTH-1:0] fb_rdata;

    wire hsync;
    wire vsync;
    wire video_active;
    wire [COLOR_DEPTH-1:0] rgb;

    // DUT Instantiation
    vga_controller #(
        .H_VISIBLE   (H_VISIBLE),
        .V_VISIBLE   (V_VISIBLE),
        .COLOR_DEPTH (COLOR_DEPTH)
    ) dut (
        .pclk         (pclk),
        .rst_n        (rst_n),
        .fb_addr      (fb_addr),
        .fb_rdata     (fb_rdata),
        .hsync        (hsync),
        .vsync        (vsync),
        .video_active (video_active),
        .rgb          (rgb)
    );

    // Pixel Clock Generation (25 MHz = 40 ns period)
    initial pclk = 0;
    always #20 pclk = ~pclk;

    integer test_errors = 0;
    integer active_pixel_count = 0;
    integer hsync_pulse_count = 0;

    // Monitor pixel clock cycles when counting is enabled
    reg enable_count;
    always @(posedge pclk) begin
        if (rst_n && enable_count) begin
            if (video_active) begin
                active_pixel_count <= active_pixel_count + 1;
            end
            if (hsync) begin
                hsync_pulse_count <= hsync_pulse_count + 1;
            end
        end
    end

    initial begin
        rst_n = 0;
        enable_count = 0;
        fb_rdata = 8'hE0; // Red

        #80;
        @(posedge pclk);
        rst_n = 1;
        #40;

        $display("=== [TEST 1] Active Video Window & RGB Blanking Check ===");
        @(posedge pclk);
        if (video_active) begin
            if (rgb !== 8'hE0) begin
                $display("ERROR: Video active RGB expected 0xE0, got 0x%h", rgb);
                test_errors = test_errors + 1;
            end
        end

        // Wait for start of next active line
        wait(!video_active);
        wait(video_active);
        active_pixel_count = 0;
        hsync_pulse_count = 0;
        enable_count = 1;

        // Run for exactly one horizontal line period (800 pixel clocks = 32,000 ns)
        #32_000;
        enable_count = 0;

        $display("=== [TEST 2] Horizontal Line Timing Verification ===");
        if (hsync_pulse_count !== 96) begin
            $display("ERROR: HSYNC pulse width expected 96 clocks, got %0d", hsync_pulse_count);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] HSYNC pulse width = 96 clocks.");
        end

        if (active_pixel_count !== 640) begin
            $display("ERROR: Active line pixel count expected 640, got %0d", active_pixel_count);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Active line pixel count = 640.");
        end

        $display("==================================================");
        if (test_errors == 0) begin
            $display(">>> ALL VGA CONTROLLER UNIT TESTS PASSED <<<");
        end else begin
            $display(">>> VGA CONTROLLER UNIT TESTS FAILED WITH %0d ERRORS <<<", test_errors);
        end
        $display("==================================================");

        $finish;
    end

endmodule
