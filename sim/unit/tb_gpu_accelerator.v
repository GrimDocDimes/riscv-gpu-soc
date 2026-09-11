// Self-checking Unit Testbench for GPU Accelerator
`timescale 1ns/1ps

module tb_gpu_accelerator;

    parameter FRAME_WIDTH  = 640;
    parameter FRAME_HEIGHT = 480;
    parameter COLOR_DEPTH  = 8;
    localparam FB_ADDR_W   = $clog2(FRAME_WIDTH * FRAME_HEIGHT);

    // Clock and Reset
    reg clk;
    reg rst_n;

    // AXI-Lite Interface
    reg [31:0]  s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;
    reg [31:0]  s_axi_wdata;
    reg [3:0]   s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;
    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    reg         s_axi_bready;

    reg [31:0]  s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    reg         s_axi_rready;

    // Framebuffer outputs
    wire                 fb_we;
    wire [FB_ADDR_W-1:0] fb_addr;
    wire [7:0]           fb_wdata;

    // DUT Instantiation
    gpu_accelerator #(
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .COLOR_DEPTH  (COLOR_DEPTH)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .fb_we         (fb_we),
        .fb_addr       (fb_addr),
        .fb_wdata      (fb_wdata)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // Register Map
    localparam ADDR_CTRL   = 8'h00;
    localparam ADDR_STATUS = 8'h04;
    localparam ADDR_CMD    = 8'h08;
    localparam ADDR_X0     = 8'h0C;
    localparam ADDR_Y0     = 8'h10;
    localparam ADDR_X1     = 8'h14;
    localparam ADDR_Y1     = 8'h18;
    localparam ADDR_COLOR  = 8'h1C;
    localparam ADDR_WIDTH  = 8'h20;
    localparam ADDR_HEIGHT = 8'h24;

    // Commands
    localparam CMD_NOP   = 4'h0;
    localparam CMD_PIXEL = 4'h1;
    localparam CMD_LINE  = 4'h2;
    localparam CMD_RECT  = 4'h3;
    localparam CMD_CLEAR = 4'h4;

    integer test_errors = 0;
    integer fb_write_count = 0;

    // Framebuffer write monitor
    always @(posedge clk) begin
        if (fb_we) begin
            fb_write_count <= fb_write_count + 1;
        end
    end

    // Task: AXI-Lite Write Register
    task axi_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            s_axi_awaddr  <= {24'h0, addr};
            s_axi_awvalid <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1'b1;
            s_axi_bready  <= 1'b1;

            fork
                begin
                    wait(s_axi_awready);
                    @(posedge clk);
                    s_axi_awvalid <= 1'b0;
                end
                begin
                    wait(s_axi_wready);
                    @(posedge clk);
                    s_axi_wvalid <= 1'b0;
                end
            join

            wait(s_axi_bvalid);
            @(posedge clk);
            s_axi_bready <= 1'b0;
        end
    endtask

    // Task: AXI-Lite Read Register
    task axi_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            s_axi_araddr  <= {24'h0, addr};
            s_axi_arvalid <= 1'b1;
            s_axi_rready  <= 1'b1;

            wait(s_axi_arready);
            @(posedge clk);
            s_axi_arvalid <= 1'b0;

            wait(s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge clk);
            s_axi_rready <= 1'b0;
        end
    endtask

    // Task: Wait until GPU is not busy
    task wait_gpu_idle();
        reg [31:0] status;
        begin
            status = 32'h1;
            while (status[0] == 1'b1) begin
                axi_read(ADDR_STATUS, status);
            end
        end
    endtask

    // Simulation Flow
    reg [31:0] read_val;

    initial begin
        // Signal init
        rst_n = 0;
        s_axi_awaddr = 0; s_axi_awvalid = 0;
        s_axi_wdata = 0; s_axi_wstrb = 0; s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0;
        s_axi_rready = 0;

        #40;
        rst_n = 1;
        #20;

        $display("=== [TEST 1] AXI-Lite Register R/W Check ===");
        axi_write(ADDR_X0, 32'd100);
        axi_read(ADDR_X0, read_val);
        if (read_val[15:0] !== 16'd100) begin
            $display("ERROR: ADDR_X0 readback expected 100, got %d", read_val);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] ADDR_X0 readback = 100");
        end

        axi_write(ADDR_Y0, 32'd50);
        axi_read(ADDR_Y0, read_val);
        if (read_val[15:0] !== 16'd50) begin
            $display("ERROR: ADDR_Y0 readback expected 50, got %d", read_val);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] ADDR_Y0 readback = 50");
        end

        axi_write(ADDR_COLOR, 32'hE0); // Red (RGB332)
        axi_read(ADDR_COLOR, read_val);
        if (read_val[7:0] !== 8'hE0) begin
            $display("ERROR: ADDR_COLOR readback expected 0xE0, got %h", read_val);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] ADDR_COLOR readback = 0xE0");
        end

        $display("=== [TEST 2] Single Pixel Draw (CMD_PIXEL) ===");
        fb_write_count = 0;
        axi_write(ADDR_X0, 32'd10);
        axi_write(ADDR_Y0, 32'd20);
        axi_write(ADDR_COLOR, 32'h1C); // Green
        axi_write(ADDR_CMD, CMD_PIXEL);

        wait_gpu_idle();
        if (fb_write_count !== 1) begin
            $display("ERROR: CMD_PIXEL wrote %d pixels instead of 1", fb_write_count);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] CMD_PIXEL wrote 1 pixel correctly.");
        end

        $display("=== [TEST 3] Rectangle Fill (CMD_RECT) ===");
        fb_write_count = 0;
        axi_write(ADDR_X0, 32'd0);
        axi_write(ADDR_Y0, 32'd0);
        axi_write(ADDR_WIDTH, 32'd10);
        axi_write(ADDR_HEIGHT, 32'd5);
        axi_write(ADDR_COLOR, 32'h03); // Blue
        axi_write(ADDR_CMD, CMD_RECT);

        wait_gpu_idle();
        if (fb_write_count !== 50) begin
            $display("ERROR: CMD_RECT (10x5) wrote %d pixels instead of 50", fb_write_count);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] CMD_RECT wrote 50 pixels (10x5 fill) correctly.");
        end

        $display("=== [TEST 4] Line Draw (CMD_LINE) ===");
        fb_write_count = 0;
        axi_write(ADDR_X0, 32'd0);
        axi_write(ADDR_Y0, 32'd0);
        axi_write(ADDR_X1, 32'd10);
        axi_write(ADDR_Y1, 32'd0);
        axi_write(ADDR_COLOR, 32'hFF); // White
        axi_write(ADDR_CMD, CMD_LINE);

        wait_gpu_idle();
        if (fb_write_count < 10) begin
            $display("ERROR: CMD_LINE horizontal 11-pixel line wrote %d pixels", fb_write_count);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] CMD_LINE rendered horizontal line (%0d pixels).", fb_write_count);
        end

        $display("==================================================");
        if (test_errors == 0) begin
            $display(">>> ALL GPU ACCELERATOR UNIT TESTS PASSED <<<");
        end else begin
            $display(">>> GPU ACCELERATOR UNIT TESTS FAILED WITH %0d ERRORS <<<", test_errors);
        end
        $display("==================================================");

        $finish;
    end

endmodule
