// Simple Block RAM for instruction/data memory
// Single-port synchronous RAM

module block_ram #(
    parameter ADDR_WIDTH = 14,  // 16K words = 64KB
    parameter DATA_WIDTH = 32,
    parameter INIT_FILE = ""
)(
    input wire clk,
    input wire rst_n,
    
    input wire valid,
    output reg ready,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [3:0] wstrb,
    output reg [DATA_WIDTH-1:0] rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];
    
    // Initialize memory
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end else begin
            // For synthesis, BRAMs are initialized to 0 by default
            // The loop below is only needed for simulation if not using readmemh
`ifdef SIMULATION
            for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
                ram[i] = 32'h00000013;  // NOP instruction
`endif
        end
    end
    
    // Memory array access (No reset for BRAM inference)
    always @(posedge clk) begin
        if (valid) begin
            // Write
            if (wstrb[0]) ram[addr][7:0]   <= wdata[7:0];
            if (wstrb[1]) ram[addr][15:8]  <= wdata[15:8];
            if (wstrb[2]) ram[addr][23:16] <= wdata[23:16];
            if (wstrb[3]) ram[addr][31:24] <= wdata[31:24];
            
            // Read
            rdata <= ram[addr];
        end
    end

    // Control logic (With reset)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else begin
            if (valid && !ready) begin
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

endmodule
