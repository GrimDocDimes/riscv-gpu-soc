// Self-checking Unit Testbench for Memory Interconnect
`timescale 1ns/1ps

module tb_mem_interconnect;

    reg clk;
    reg rst_n;

    // CPU native interface
    reg         mem_valid;
    wire        mem_ready;
    reg [31:0]  mem_addr;
    reg [31:0]  mem_wdata;
    reg [3:0]   mem_wstrb;
    wire [31:0] mem_rdata;

    // IMEM
    wire        imem_valid;
    reg         imem_ready;
    wire [31:0] imem_addr;
    reg [31:0]  imem_rdata;

    // DMEM
    wire        dmem_valid;
    reg         dmem_ready;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_wstrb;
    reg [31:0]  dmem_rdata;

    // GPU AXI-Lite
    wire [31:0] gpu_awaddr;
    wire        gpu_awvalid;
    reg         gpu_awready;
    wire [31:0] gpu_wdata;
    wire [3:0]  gpu_wstrb;
    wire        gpu_wvalid;
    reg         gpu_wready;
    reg [1:0]   gpu_bresp;
    reg         gpu_bvalid;
    wire        gpu_bready;
    wire [31:0] gpu_araddr;
    wire        gpu_arvalid;
    reg         gpu_arready;
    reg [31:0]  gpu_rdata;
    reg [1:0]   gpu_rresp;
    reg         gpu_rvalid;
    wire        gpu_rready;

    // DUT Instantiation
    mem_interconnect #(
        .FRAME_WIDTH  (640),
        .FRAME_HEIGHT (480)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .mem_valid   (mem_valid),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),

        .imem_valid  (imem_valid),
        .imem_ready  (imem_ready),
        .imem_addr   (imem_addr),
        .imem_rdata  (imem_rdata),

        .dmem_valid  (dmem_valid),
        .dmem_ready  (dmem_ready),
        .dmem_addr   (dmem_addr),
        .dmem_wdata  (dmem_wdata),
        .dmem_wstrb  (dmem_wstrb),
        .dmem_rdata  (dmem_rdata),

        .gpu_awaddr  (gpu_awaddr),
        .gpu_awvalid (gpu_awvalid),
        .gpu_awready (gpu_awready),
        .gpu_wdata   (gpu_wdata),
        .gpu_wstrb   (gpu_wstrb),
        .gpu_wvalid  (gpu_wvalid),
        .gpu_wready  (gpu_wready),
        .gpu_bresp   (gpu_bresp),
        .gpu_bvalid  (gpu_bvalid),
        .gpu_bready  (gpu_bready),
        .gpu_araddr  (gpu_araddr),
        .gpu_arvalid (gpu_arvalid),
        .gpu_arready (gpu_arready),
        .gpu_rdata   (gpu_rdata),
        .gpu_rresp   (gpu_rresp),
        .gpu_rvalid  (gpu_rvalid),
        .gpu_rready  (gpu_rready)
    );

    // Clock generation (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    integer test_errors = 0;

    initial begin
        rst_n = 0;
        mem_valid = 0; mem_addr = 0; mem_wdata = 0; mem_wstrb = 0;
        imem_ready = 1; imem_rdata = 32'h12345678;
        dmem_ready = 1; dmem_rdata = 32'h87654321;
        gpu_awready = 1; gpu_wready = 1; gpu_bvalid = 0; gpu_bresp = 0;
        gpu_arready = 1; gpu_rvalid = 0; gpu_rresp = 0; gpu_rdata = 32'hA5A5A5A5;

        #40;
        rst_n = 1;
        #20;

        $display("=== [TEST 1] IMEM Access (Address 0x00000004) ===");
        @(posedge clk);
        mem_addr  <= 32'h00000004;
        mem_wstrb <= 4'b0000; // Read
        mem_valid <= 1'b1;

        wait(mem_ready);
        if (mem_rdata !== 32'h12345678) begin
            $display("ERROR: IMEM Read expected 0x12345678, got 0x%h", mem_rdata);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] IMEM Read successful (rdata=0x%h)", mem_rdata);
        end
        @(posedge clk);
        mem_valid <= 1'b0;
        #20;

        $display("=== [TEST 2] DMEM Access (Address 0x00008010) ===");
        @(posedge clk);
        mem_addr  <= 32'h00008010;
        mem_wstrb <= 4'b0000;
        mem_valid <= 1'b1;

        wait(mem_ready);
        if (mem_rdata !== 32'h87654321) begin
            $display("ERROR: DMEM Read expected 0x87654321, got 0x%h", mem_rdata);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] DMEM Read successful (rdata=0x%h)", mem_rdata);
        end
        @(posedge clk);
        mem_valid <= 1'b0;
        #20;

        $display("=== [TEST 3] Out-of-Bounds Address (0x20000000) ===");
        @(posedge clk);
        mem_addr  <= 32'h20000000;
        mem_wstrb <= 4'b0000;
        mem_valid <= 1'b1;

        wait(mem_ready);
        if (mem_rdata !== 32'hDEADBEEF) begin
            $display("ERROR: Out-of-bounds expected 0xDEADBEEF, got 0x%h", mem_rdata);
            test_errors = test_errors + 1;
        end else begin
            $display("[PASS] Out-of-bounds returned 0xDEADBEEF correctly.");
        end
        @(posedge clk);
        mem_valid <= 1'b0;
        #20;

        $display("==================================================");
        if (test_errors == 0) begin
            $display(">>> ALL MEMORY INTERCONNECT UNIT TESTS PASSED <<<");
        end else begin
            $display(">>> MEMORY INTERCONNECT UNIT TESTS FAILED WITH %0d ERRORS <<<", test_errors);
        end
        $display("==================================================");

        $finish;
    end

endmodule
