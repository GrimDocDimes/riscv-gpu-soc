// Memory Interconnect
// Connects PicoRV32 native interface to memory-mapped peripherals

module mem_interconnect #(
    parameter FRAME_WIDTH = 640,
    parameter FRAME_HEIGHT = 480
)(
    input wire clk,
    input wire rst_n,
    
    // PicoRV32 native memory interface
    input wire mem_valid,
    output reg mem_ready,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    input wire [3:0] mem_wstrb,
    output reg [31:0] mem_rdata,
    
    // Instruction memory interface
    output reg imem_valid,
    input wire imem_ready,
    output wire [31:0] imem_addr,
    input wire [31:0] imem_rdata,
    
    // Data memory interface
    output reg dmem_valid,
    input wire dmem_ready,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0] dmem_wstrb,
    input wire [31:0] dmem_rdata,
    
    // GPU AXI-Lite interface
    output reg [31:0] gpu_awaddr,
    output reg gpu_awvalid,
    input wire gpu_awready,
    output reg [31:0] gpu_wdata,
    output reg [3:0] gpu_wstrb,
    output reg gpu_wvalid,
    input wire gpu_wready,
    input wire [1:0] gpu_bresp,
    input wire gpu_bvalid,
    output reg gpu_bready,
    output reg [31:0] gpu_araddr,
    output reg gpu_arvalid,
    input wire gpu_arready,
    input wire [31:0] gpu_rdata,
    input wire [1:0] gpu_rresp,
    input wire gpu_rvalid,
    output reg gpu_rready
);

    // Memory map
    localparam IMEM_BASE  = 32'h0000_0000;  // 0x00000000 - 0x00007FFF (32KB)
    localparam IMEM_SIZE  = 32'h0000_8000;
    localparam DMEM_BASE  = 32'h0000_8000;  // 0x00008000 - 0x0000FFFF (32KB)
    localparam DMEM_SIZE  = 32'h0000_8000;
    localparam GPU_BASE   = 32'h1000_0000;  // 0x10000000 - 0x100000FF
    localparam GPU_SIZE   = 32'h0000_0100;
    
    // Address decode
    wire sel_imem = (mem_addr >= IMEM_BASE) && (mem_addr < (IMEM_BASE + IMEM_SIZE));
    wire sel_dmem = (mem_addr >= DMEM_BASE) && (mem_addr < (DMEM_BASE + DMEM_SIZE));
    wire sel_gpu  = (mem_addr >= GPU_BASE) && (mem_addr < (GPU_BASE + GPU_SIZE));
    
    // Write operation
    wire is_write = |mem_wstrb;
    
    // State machine for AXI-Lite transactions
    localparam ST_IDLE = 2'h0;
    localparam ST_WRITE = 2'h1;
    localparam ST_READ = 2'h2;
    
    reg [1:0] state;
    
    assign imem_addr = mem_addr;
    assign dmem_addr = mem_addr - DMEM_BASE;
    assign dmem_wdata = mem_wdata;
    assign dmem_wstrb = mem_wstrb;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
            imem_valid <= 1'b0;
            dmem_valid <= 1'b0;
            gpu_awaddr <= 32'h0;
            gpu_awvalid <= 1'b0;
            gpu_wdata <= 32'h0;
            gpu_wstrb <= 4'h0;
            gpu_wvalid <= 1'b0;
            gpu_bready <= 1'b0;
            gpu_araddr <= 32'h0;
            gpu_arvalid <= 1'b0;
            gpu_rready <= 1'b0;
            state <= ST_IDLE;
        end else begin
            case (state)
                ST_IDLE: begin
                    mem_ready <= 1'b0;
                    
                    if (mem_valid && !mem_ready) begin
                        if (sel_imem) begin
                            // Instruction memory access (read-only)
                            imem_valid <= 1'b1;
                            if (imem_ready) begin
                                mem_rdata <= imem_rdata;
                                mem_ready <= 1'b1;
                                imem_valid <= 1'b0;
                            end
                        end else if (sel_dmem) begin
                            // Data memory access
                            dmem_valid <= 1'b1;
                            if (dmem_ready) begin
                                mem_rdata <= dmem_rdata;
                                mem_ready <= 1'b1;
                                dmem_valid <= 1'b0;
                            end
                        end else if (sel_gpu) begin
                            // GPU peripheral access via AXI-Lite
                            if (is_write) begin
                                state <= ST_WRITE;
                                gpu_awaddr <= mem_addr;
                                gpu_awvalid <= 1'b1;
                                gpu_wdata <= mem_wdata;
                                gpu_wstrb <= mem_wstrb;
                                gpu_wvalid <= 1'b1;
                            end else begin
                                state <= ST_READ;
                                gpu_araddr <= mem_addr;
                                gpu_arvalid <= 1'b1;
                                gpu_rready <= 1'b1;
                            end
                        end else begin
                            // Invalid address
                            mem_rdata <= 32'hDEADBEEF;
                            mem_ready <= 1'b1;
                        end
                    end
                end
                
                ST_WRITE: begin
                    // AXI-Lite write transaction
                    if (gpu_awready) gpu_awvalid <= 1'b0;
                    if (gpu_wready) gpu_wvalid <= 1'b0;
                    
                    if (gpu_bvalid) begin
                        gpu_bready <= 1'b1;
                        mem_ready <= 1'b1;
                        state <= ST_IDLE;
                    end
                    
                    if (gpu_bready && gpu_bvalid) begin
                        gpu_bready <= 1'b0;
                    end
                end
                
                ST_READ: begin
                    // AXI-Lite read transaction
                    if (gpu_arready) gpu_arvalid <= 1'b0;
                    
                    if (gpu_rvalid && gpu_rready) begin
                        mem_rdata <= gpu_rdata;
                        mem_ready <= 1'b1;
                        gpu_rready <= 1'b0;
                        state <= ST_IDLE;
                    end
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
