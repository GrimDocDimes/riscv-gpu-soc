// Dual-Port RAM for Frame Buffer
// Port A: Write (GPU accelerator)
// Port B: Read (VGA controller)

module dual_port_ram #(
    parameter ADDR_WIDTH = 19,  // 2^19 = 512K addresses
    parameter DATA_WIDTH = 8    // 8-bit color
)(
    // Port A - Write port (GPU)
    input wire clk_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    
    // Port B - Read port (VGA)
    input wire clk_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    output reg [DATA_WIDTH-1:0] dout_b
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];
    
    // Initialize memory to black
    integer i;
    initial begin
`ifdef SIMULATION
        for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
            ram[i] = 8'h00;
`endif
    end
    
    // Port A - Write
    always @(posedge clk_a) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
            dout_a <= din_a;  // Write-first mode
        end else begin
            dout_a <= ram[addr_a];
        end
    end
    
    // Port B - Read only
    always @(posedge clk_b) begin
        dout_b <= ram[addr_b];
    end

endmodule
