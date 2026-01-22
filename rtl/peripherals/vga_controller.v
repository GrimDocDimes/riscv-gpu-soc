// VGA Controller Module
// Generates VGA timing signals and reads from frame buffer

module vga_controller #(
    parameter H_VISIBLE = 640,
    parameter H_FRONT = 16,
    parameter H_SYNC = 96,
    parameter H_BACK = 48,
    parameter V_VISIBLE = 480,
    parameter V_FRONT = 10,
    parameter V_SYNC = 2,
    parameter V_BACK = 33,
    parameter COLOR_DEPTH = 8
)(
    // Pixel clock (25.175 MHz for 640x480@60Hz)
    input wire pclk,
    input wire rst_n,
    
    // Frame buffer interface
    output wire [$clog2(H_VISIBLE*V_VISIBLE)-1:0] fb_addr,
    input wire [COLOR_DEPTH-1:0] fb_rdata,
    
    // VGA output signals
    output wire hsync,
    output wire vsync,
    output wire video_active,
    output wire [COLOR_DEPTH-1:0] rgb
);

    localparam H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;
    localparam V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;
    
    reg [$clog2(H_TOTAL)-1:0] h_count;
    reg [$clog2(V_TOTAL)-1:0] v_count;
    
    // Horizontal counter
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            h_count <= 0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 0;
        else
            h_count <= h_count + 1;
    end
    
    // Vertical counter
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            v_count <= 0;
        else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end
    end
    
    // Generate sync signals
    assign hsync = (h_count >= H_VISIBLE + H_FRONT) && 
                   (h_count < H_VISIBLE + H_FRONT + H_SYNC);
    assign vsync = (v_count >= V_VISIBLE + V_FRONT) && 
                   (v_count < V_VISIBLE + V_FRONT + V_SYNC);
    
    // Video active region
    assign video_active = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    
    // Frame buffer address calculation
    assign fb_addr = (v_count * H_VISIBLE) + h_count;
    
    // Output pixel data (only during active video)
    assign rgb = video_active ? fb_rdata : {COLOR_DEPTH{1'b0}};

endmodule
