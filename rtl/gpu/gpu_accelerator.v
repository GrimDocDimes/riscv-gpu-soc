// GPU Accelerator Top Module
// Implements 2D graphics primitives with AXI-Lite interface

module gpu_accelerator #(
    parameter FRAME_WIDTH = 640,
    parameter FRAME_HEIGHT = 480,
    parameter COLOR_DEPTH = 8
)(
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Lite Slave Interface
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Frame buffer interface
    output reg fb_we,
    output reg [$clog2(FRAME_WIDTH*FRAME_HEIGHT)-1:0] fb_addr,
    output reg [COLOR_DEPTH-1:0] fb_wdata
);

    // Register map
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
    
    // Command definitions
    localparam CMD_NOP   = 4'h0;
    localparam CMD_PIXEL = 4'h1;
    localparam CMD_LINE  = 4'h2;
    localparam CMD_RECT  = 4'h3;
    localparam CMD_CLEAR = 4'h4;
    
    // Internal registers
    reg [31:0] ctrl_reg;
    reg [15:0] x0_reg, y0_reg, x1_reg, y1_reg;
    reg [COLOR_DEPTH-1:0] color_reg;
    reg [15:0] width_reg, height_reg;
    
    // State machine
    localparam STATE_IDLE  = 4'h0;
    localparam STATE_PIXEL = 4'h1;
    localparam STATE_LINE  = 4'h2;
    localparam STATE_RECT  = 4'h3;
    localparam STATE_CLEAR = 4'h4;
    
    reg [3:0] state, next_state;
    reg busy;
    
    // Bresenham line drawing registers
    reg signed [17:0] dx, dy, sx, sy, err, e2;
    reg [15:0] x_cur, y_cur;
    
    // Rectangle fill counters
    reg [15:0] rect_x, rect_y;
    reg        rect_init;  // 1 = first cycle in STATE_RECT, load counters
    reg [31:0] clear_addr;
    
    //==========================================================================
    // AXI-Lite Write Channel
    //==========================================================================
    reg [31:0] awaddr_reg;
    reg [31:0] wdata_reg;
    
    // Write address channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            awaddr_reg <= 32'h0;
        end else begin
            if (s_axi_awvalid && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                awaddr_reg <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            wdata_reg <= 32'h0;
        end else begin
            if (s_axi_wvalid && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
                wdata_reg <= s_axi_wdata;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    
    // Write response channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_wready && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;  // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Register writes
    reg cmd_valid;
    reg [3:0] cmd_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 32'h0;
            x0_reg <= 16'h0;
            y0_reg <= 16'h0;
            x1_reg <= 16'h0;
            y1_reg <= 16'h0;
            color_reg <= 8'h0;
            width_reg <= 16'h0;
            height_reg <= 16'h0;
            cmd_valid <= 1'b0;
            cmd_reg <= 4'h0;
        end else begin
            cmd_valid <= 1'b0;
            if (s_axi_wready && s_axi_awready) begin
                case (awaddr_reg[7:0])
                    ADDR_CTRL:   ctrl_reg <= wdata_reg;
                    ADDR_X0:     x0_reg <= wdata_reg[15:0];
                    ADDR_Y0:     y0_reg <= wdata_reg[15:0];
                    ADDR_X1:     x1_reg <= wdata_reg[15:0];
                    ADDR_Y1:     y1_reg <= wdata_reg[15:0];
                    ADDR_COLOR:  color_reg <= wdata_reg[COLOR_DEPTH-1:0];
                    ADDR_WIDTH:  width_reg <= wdata_reg[15:0];
                    ADDR_HEIGHT: height_reg <= wdata_reg[15:0];
                    ADDR_CMD: begin
                        cmd_reg <= wdata_reg[3:0];
                        cmd_valid <= 1'b1;
                    end
                endcase
            end
        end
    end
    
    //==========================================================================
    // AXI-Lite Read Channel
    //==========================================================================
    reg [31:0] araddr_reg;
    
    // Read address channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            araddr_reg <= 32'h0;
        end else begin
            if (s_axi_arvalid && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
                araddr_reg <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;
        end else begin
            if (s_axi_arready && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;  // OKAY
                case (araddr_reg[7:0])
                    ADDR_CTRL:   s_axi_rdata <= ctrl_reg;
                    ADDR_STATUS: s_axi_rdata <= {31'h0, busy};
                    ADDR_X0:     s_axi_rdata <= {16'h0, x0_reg};
                    ADDR_Y0:     s_axi_rdata <= {16'h0, y0_reg};
                    ADDR_X1:     s_axi_rdata <= {16'h0, x1_reg};
                    ADDR_Y1:     s_axi_rdata <= {16'h0, y1_reg};
                    ADDR_COLOR:  s_axi_rdata <= {24'h0, color_reg};
                    ADDR_WIDTH:  s_axi_rdata <= {16'h0, width_reg};
                    ADDR_HEIGHT: s_axi_rdata <= {16'h0, height_reg};
                    default:     s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    //==========================================================================
    // Command Execution State Machine
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            next_state <= STATE_IDLE;
            busy <= 1'b0;
            fb_we <= 1'b0;
            fb_addr <= 0;
            fb_wdata <= 0;
            
            // Bresenham variables
            dx <= 0;
            dy <= 0;
            sx <= 0;
            sy <= 0;
            err <= 0;
            x_cur <= 0;
            y_cur <= 0;
            
            // Rectangle variables
            rect_x     <= 0;
            rect_y     <= 0;
            rect_init  <= 1'b0;
            clear_addr <= 0;
            
        end else begin
            // Command trigger
            if (cmd_valid && state == STATE_IDLE) begin
                case (cmd_reg)
                    CMD_PIXEL: next_state <= STATE_PIXEL;
                    CMD_LINE:  next_state <= STATE_LINE;
                    CMD_RECT:  begin next_state <= STATE_RECT; rect_init <= 1'b1; end
                    CMD_CLEAR: next_state <= STATE_CLEAR;
                    default:   next_state <= STATE_IDLE;
                endcase
            end

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    fb_we <= 1'b0;
                    if (next_state != STATE_IDLE) begin
                        state <= next_state;
                        busy <= 1'b1;
                        next_state <= STATE_IDLE;
                    end
                end
                
                STATE_PIXEL: begin
                    // Single pixel write
                    if (x0_reg < FRAME_WIDTH && y0_reg < FRAME_HEIGHT) begin
                        fb_addr <= y0_reg * FRAME_WIDTH + x0_reg;
                        fb_wdata <= color_reg;
                        fb_we <= 1'b1;
                    end
                    state <= STATE_IDLE;
                end
                
                STATE_LINE: begin
                    // Bresenham line drawing algorithm
                    if (busy && state == STATE_LINE) begin
                        // First cycle: initialize
                        if (dx == 0 && dy == 0) begin
                            dx <= (x1_reg > x0_reg) ? (x1_reg - x0_reg) : (x0_reg - x1_reg);
                            dy <= (y1_reg > y0_reg) ? (y0_reg - y1_reg) : (y1_reg - y0_reg);
                            sx <= (x0_reg < x1_reg) ? 1 : -1;
                            sy <= (y0_reg < y1_reg) ? 1 : -1;
                            x_cur <= x0_reg;
                            y_cur <= y0_reg;
                            err <= ((x1_reg > x0_reg) ? (x1_reg - x0_reg) : (x0_reg - x1_reg)) + 
                                   ((y1_reg > y0_reg) ? (y0_reg - y1_reg) : (y1_reg - y0_reg));
                            fb_we <= 1'b0;
                        end else begin
                            // Draw current pixel
                            if (x_cur < FRAME_WIDTH && y_cur < FRAME_HEIGHT) begin
                                fb_addr <= y_cur * FRAME_WIDTH + x_cur;
                                fb_wdata <= color_reg;
                                fb_we <= 1'b1;
                            end else begin
                                fb_we <= 1'b0;
                            end
                            
                            // Check if done
                            if (x_cur == x1_reg && y_cur == y1_reg) begin
                                state <= STATE_IDLE;
                                dx <= 0;
                                dy <= 0;
                            end else begin
                                // Bresenham step — use full signed register for direction
                                e2 <= err * 2;
                                if (e2 >= dy) begin
                                    err   <= err + dy;
                                    x_cur <= $signed({1'b0, x_cur}) + sx;
                                end
                                if (e2 <= dx) begin
                                    err   <= err + dx;
                                    y_cur <= $signed({1'b0, y_cur}) + sy;
                                end
                            end
                        end
                    end
                end
                
                STATE_RECT: begin
                    // Rectangle fill — use rect_init flag for first-cycle init
                    // so we don't deadlock on the (rect_x==0 && rect_y==0) condition
                    if (rect_init) begin
                        // First cycle: reset counters and begin
                        rect_x    <= 0;
                        rect_y    <= 0;
                        rect_init <= 1'b0;
                        fb_we     <= 1'b0;
                    end else if (rect_y < height_reg) begin
                        // Fill pixels row by row
                        if (rect_x < width_reg) begin
                            if ((x0_reg + rect_x) < FRAME_WIDTH &&
                                (y0_reg + rect_y) < FRAME_HEIGHT) begin
                                fb_addr  <= (y0_reg + rect_y) * FRAME_WIDTH + (x0_reg + rect_x);
                                fb_wdata <= color_reg;
                                fb_we    <= 1'b1;
                            end else begin
                                fb_we <= 1'b0;
                            end
                            rect_x <= rect_x + 1;
                        end else begin
                            // End of row — advance to next row
                            rect_x <= 0;
                            rect_y <= rect_y + 1;
                            fb_we  <= 1'b0;
                        end
                    end else begin
                        // All rows done
                        state  <= STATE_IDLE;
                        rect_x <= 0;
                        rect_y <= 0;
                        fb_we  <= 1'b0;
                    end
                end
                
                STATE_CLEAR: begin
                    // Clear entire frame buffer
                    if (clear_addr < (FRAME_WIDTH * FRAME_HEIGHT)) begin
                        fb_addr <= clear_addr[$clog2(FRAME_WIDTH*FRAME_HEIGHT)-1:0];
                        fb_wdata <= color_reg;
                        fb_we <= 1'b1;
                        clear_addr <= clear_addr + 1;
                    end else begin
                        state <= STATE_IDLE;
                        clear_addr <= 0;
                        fb_we <= 1'b0;
                    end
                end
                
                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
