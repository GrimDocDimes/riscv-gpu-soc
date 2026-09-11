// riscv_gpu_soc_sim.v
// Simulation-only wrapper for the RISC-V + GPU SoC
//
// Purpose: Bypasses Xilinx-specific primitives that cannot be elaborated
//   without vendor simulation models:
//     - clk_wiz_0  (MMCM-based clock wizard)
//     - OSERDESE2  (10:1 serializer)
//     - OBUFDS     (differential output buffer)
//
// Accepts flat clock inputs directly and exposes flat VGA-style outputs
// for waveform-based simulation and frame-buffer image extraction.
//
// This file is EXCLUDED from synthesis (not referenced in vivado_build.tcl).

`define SIMULATION

module riscv_gpu_soc_sim #(
    parameter FRAME_WIDTH  = 640,
    parameter FRAME_HEIGHT = 480,
    parameter COLOR_DEPTH  = 8
)(
    // Clocks provided directly (no clock wizard in sim)
    input  wire clk_50mhz,   // System clock  (50 MHz)
    input  wire clk_25mhz,   // Pixel clock   (25 MHz)
    input  wire rst_n,

    // Flat VGA outputs (instead of HDMI differential pairs)
    output wire vga_hsync,
    output wire vga_vsync,
    output wire vga_active,
    output wire [COLOR_DEPTH-1:0] vga_rgb,

    // Debug LEDs
    output wire [3:0] led
);

    // =====================================================================
    // PicoRV32 memory interface
    // =====================================================================
    wire        mem_valid;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire  [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire        mem_instr;

    wire        imem_valid;
    wire        imem_ready;
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    wire        dmem_valid;
    wire        dmem_ready;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire  [3:0] dmem_wstrb;
    wire [31:0] dmem_rdata;

    // GPU AXI-Lite interface
    wire [31:0] gpu_awaddr;
    wire        gpu_awvalid;
    wire        gpu_awready;
    wire [31:0] gpu_wdata;
    wire  [3:0] gpu_wstrb;
    wire        gpu_wvalid;
    wire        gpu_wready;
    wire  [1:0] gpu_bresp;
    wire        gpu_bvalid;
    wire        gpu_bready;
    wire [31:0] gpu_araddr;
    wire        gpu_arvalid;
    wire        gpu_arready;
    wire [31:0] gpu_rdata;
    wire  [1:0] gpu_rresp;
    wire        gpu_rvalid;
    wire        gpu_rready;

    // Pre-compute frame buffer address width as a localparam
    // (avoids $clog2 in wire declarations which some iverilog versions reject)
    localparam FB_ADDR_W = $clog2(FRAME_WIDTH * FRAME_HEIGHT);

    // Frame buffer signals
    wire                    fb_we_gpu;
    wire [FB_ADDR_W-1:0]    fb_addr_gpu;
    wire [COLOR_DEPTH-1:0]  fb_wdata_gpu;
    wire [FB_ADDR_W-1:0]    fb_addr_vga;
    wire [COLOR_DEPTH-1:0]  fb_rdata_vga;

    // =====================================================================
    // PicoRV32 Core
    // =====================================================================
    picorv32 #(
        .ENABLE_COUNTERS    (1),
        .ENABLE_COUNTERS64  (0),
        .ENABLE_REGS_16_31  (1),
        .ENABLE_REGS_DUALPORT(1),
        .LATCHED_MEM_RDATA  (0),
        .TWO_STAGE_SHIFT    (1),
        .BARREL_SHIFTER     (0),
        .TWO_CYCLE_COMPARE  (0),
        .TWO_CYCLE_ALU      (0),
        .COMPRESSED_ISA     (0),
        .CATCH_MISALIGN     (1),
        .CATCH_ILLINSN      (1),
        .ENABLE_PCPI        (0),
        .ENABLE_MUL         (0),
        .ENABLE_FAST_MUL    (0),
        .ENABLE_DIV         (0),
        .ENABLE_IRQ         (0),
        .ENABLE_IRQ_QREGS   (0),
        .ENABLE_IRQ_TIMER   (0),
        .ENABLE_TRACE       (0),
        .REGS_INIT_ZERO     (0),
        .MASKED_IRQ         (32'h0),
        .LATCHED_IRQ        (32'h0),
        .PROGADDR_RESET     (32'h0000_0000),
        .PROGADDR_IRQ       (32'h0000_0010),
        .STACKADDR          (32'h0000_7F00)
    ) cpu (
        .clk       (clk_50mhz),
        .resetn    (rst_n),
        .trap      (),

        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata),

        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),

        .pcpi_valid (),
        .pcpi_insn  (),
        .pcpi_rs1   (),
        .pcpi_rs2   (),
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'h0),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),

        .irq (32'h0),
        .eoi (),

        .trace_valid (),
        .trace_data  ()
    );

    // =====================================================================
    // Memory Interconnect
    // =====================================================================
    mem_interconnect #(
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT)
    ) u_mem_interconnect (
        .clk       (clk_50mhz),
        .rst_n     (rst_n),

        .mem_valid (mem_valid),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata),

        .imem_valid (imem_valid),
        .imem_ready (imem_ready),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_valid (dmem_valid),
        .dmem_ready (dmem_ready),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wstrb (dmem_wstrb),
        .dmem_rdata (dmem_rdata),

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

    // =====================================================================
    // Instruction Memory (32 KB)
    // =====================================================================
    block_ram #(
        .ADDR_WIDTH (13),
        .DATA_WIDTH (32),
        .INIT_FILE  ("")         // Testbench loads firmware via $readmemh
    ) imem (
        .clk   (clk_50mhz),
        .rst_n (rst_n),
        .valid (imem_valid),
        .ready (imem_ready),
        .addr  (imem_addr[14:2]),
        .wdata (32'h0),
        .wstrb (4'h0),
        .rdata (imem_rdata)
    );

    // =====================================================================
    // Data Memory (32 KB)
    // =====================================================================
    block_ram #(
        .ADDR_WIDTH (13),
        .DATA_WIDTH (32),
        .INIT_FILE  ("")
    ) dmem (
        .clk   (clk_50mhz),
        .rst_n (rst_n),
        .valid (dmem_valid),
        .ready (dmem_ready),
        .addr  (dmem_addr[14:2]),
        .wdata (dmem_wdata),
        .wstrb (dmem_wstrb),
        .rdata (dmem_rdata)
    );

    // =====================================================================
    // GPU Accelerator
    // =====================================================================
    gpu_accelerator #(
        .FRAME_WIDTH  (FRAME_WIDTH),
        .FRAME_HEIGHT (FRAME_HEIGHT),
        .COLOR_DEPTH  (COLOR_DEPTH)
    ) gpu (
        .clk   (clk_50mhz),
        .rst_n (rst_n),

        .s_axi_awaddr  (gpu_awaddr),
        .s_axi_awvalid (gpu_awvalid),
        .s_axi_awready (gpu_awready),
        .s_axi_wdata   (gpu_wdata),
        .s_axi_wstrb   (gpu_wstrb),
        .s_axi_wvalid  (gpu_wvalid),
        .s_axi_wready  (gpu_wready),
        .s_axi_bresp   (gpu_bresp),
        .s_axi_bvalid  (gpu_bvalid),
        .s_axi_bready  (gpu_bready),
        .s_axi_araddr  (gpu_araddr),
        .s_axi_arvalid (gpu_arvalid),
        .s_axi_arready (gpu_arready),
        .s_axi_rdata   (gpu_rdata),
        .s_axi_rresp   (gpu_rresp),
        .s_axi_rvalid  (gpu_rvalid),
        .s_axi_rready  (gpu_rready),

        .fb_we    (fb_we_gpu),
        .fb_addr  (fb_addr_gpu),
        .fb_wdata (fb_wdata_gpu)
    );

    // =====================================================================
    // VGA Controller
    // =====================================================================
    vga_controller #(
        .H_VISIBLE   (FRAME_WIDTH),
        .V_VISIBLE   (FRAME_HEIGHT),
        .COLOR_DEPTH (COLOR_DEPTH)
    ) vga (
        .pclk        (clk_25mhz),
        .rst_n       (rst_n),
        .fb_addr     (fb_addr_vga),
        .fb_rdata    (fb_rdata_vga),
        .hsync       (vga_hsync),
        .vsync       (vga_vsync),
        .video_active(vga_active),
        .rgb         (vga_rgb)
    );

    // =====================================================================
    // Frame Buffer (Dual-port BRAM)
    // =====================================================================
    dual_port_ram #(
        .ADDR_WIDTH (FB_ADDR_W),
        .DATA_WIDTH (COLOR_DEPTH)
    ) frame_buffer (
        .clk_a  (clk_50mhz),
        .we_a   (fb_we_gpu),
        .addr_a (fb_addr_gpu),
        .din_a  (fb_wdata_gpu),
        .dout_a (),

        .clk_b  (clk_25mhz),
        .addr_b (fb_addr_vga),
        .dout_b (fb_rdata_vga)
    );

    // =====================================================================
    // Debug LEDs
    // =====================================================================
    assign led = {mem_valid, mem_ready, fb_we_gpu, vga_hsync};

endmodule
