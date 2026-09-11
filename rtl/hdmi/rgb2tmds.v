// rgb2tmds.v
// TMDS (Transition Minimized Differential Signaling) Encoder for HDMI output
// Implements HDMI 1.4 TMDS 8b/10b encoding for 3 data channels + clock
//
// Architecture:
//   - Three TMDS encoders (one per channel: Blue=D0, Green=D1, Red=D2)
//   - 10-bit parallel TMDS word → OSERDESE2 10:1 serializer
//   - OBUFDS differential output buffer
//
// Clock Requirements:
//   - pclk      : 25.175 MHz pixel clock
//   - pclk_x5   : 125.875 MHz (= 5× pixel clock) for serializer
//   - pclk_x10  : SERDES CLKDIV (same as pclk_x5 internally)
//
// Outputs: 4 differential pairs (clk, D0, D1, D2)

`default_nettype none

// ============================================================
// Sub-module: Single TMDS channel encoder (parallel 8b → 10b)
// Reference: DVI 1.0 Specification Section 3.3.3
// ============================================================
module tmds_encoder (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,      // 8-bit pixel data
    input  wire [1:0] ctrl_in,      // 2-bit control data (hsync/vsync on Ch0)
    input  wire       de,           // Data Enable (video_active)
    output reg  [9:0] tmds_out      // 10-bit TMDS encoded word
);

    // --- Stage 1: XOR/XNOR encode ---
    wire [8:0] q_m;
    // Count of 1s in data_in
    wire [3:0] n1_data;
    assign n1_data = data_in[0] + data_in[1] + data_in[2] + data_in[3] +
                     data_in[4] + data_in[5] + data_in[6] + data_in[7];

    // Choose XOR (bit8=1) or XNOR (bit8=0) based on number of 1s
    wire use_xnor = (n1_data > 4) || (n1_data == 4 && data_in[0] == 0);
    
    assign q_m[0] = data_in[0];
    assign q_m[1] = use_xnor ? ~(q_m[0] ^ data_in[1]) : (q_m[0] ^ data_in[1]);
    assign q_m[2] = use_xnor ? ~(q_m[1] ^ data_in[2]) : (q_m[1] ^ data_in[2]);
    assign q_m[3] = use_xnor ? ~(q_m[2] ^ data_in[3]) : (q_m[2] ^ data_in[3]);
    assign q_m[4] = use_xnor ? ~(q_m[3] ^ data_in[4]) : (q_m[3] ^ data_in[4]);
    assign q_m[5] = use_xnor ? ~(q_m[4] ^ data_in[5]) : (q_m[4] ^ data_in[5]);
    assign q_m[6] = use_xnor ? ~(q_m[5] ^ data_in[6]) : (q_m[5] ^ data_in[6]);
    assign q_m[7] = use_xnor ? ~(q_m[6] ^ data_in[7]) : (q_m[6] ^ data_in[7]);
    assign q_m[8] = ~use_xnor;  // 1 = XOR mode, 0 = XNOR mode

    // --- Stage 2: DC Balance using running disparity counter ---
    reg signed [4:0] cnt;   // Running disparity (-8 to +8)

    // Count of 1s in q_m[7:0]
    wire [3:0] n1_qm;
    assign n1_qm = q_m[0] + q_m[1] + q_m[2] + q_m[3] +
                   q_m[4] + q_m[5] + q_m[6] + q_m[7];
    // Count of 0s in q_m[7:0]
    wire [3:0] n0_qm = 4'd8 - n1_qm;

    // Control tokens (from DVI spec Table 3)
    wire [9:0] ctrl_token;
    assign ctrl_token = (ctrl_in == 2'b00) ? 10'b1101010100 :
                        (ctrl_in == 2'b01) ? 10'b0010101011 :
                        (ctrl_in == 2'b10) ? 10'b0101010100 :
                                             10'b1010101011;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 5'sd0;
            tmds_out <= 10'b1101010100;  // CTRL token 00
        end else begin
            if (!de) begin
                // Blanking interval: output control token
                tmds_out <= ctrl_token;
                cnt      <= 5'sd0;
            end else begin
                // Active video: DC-balance encoding
                if (cnt == 0 || n1_qm == n0_qm) begin
                    // No disparity bias — use q_m[8] to pick polarity
                    tmds_out[9]   <= ~q_m[8];
                    tmds_out[8]   <= q_m[8];
                    tmds_out[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];
                    cnt           <= q_m[8] ? (cnt + $signed({1'b0, n1_qm}) - $signed({1'b0, n0_qm}))
                                           : (cnt + $signed({1'b0, n0_qm}) - $signed({1'b0, n1_qm}));
                end else begin
                    if ((cnt > 0 && n1_qm > n0_qm) ||
                        (cnt < 0 && n0_qm > n1_qm)) begin
                        // Invert q_m to reduce disparity
                        tmds_out[9]   <= 1'b1;
                        tmds_out[8]   <= q_m[8];
                        tmds_out[7:0] <= ~q_m[7:0];
                        cnt           <= cnt + $signed({1'b0, {q_m[8], 1'b0}}) +
                                         $signed({1'b0, n0_qm}) - $signed({1'b0, n1_qm});
                    end else begin
                        tmds_out[9]   <= 1'b0;
                        tmds_out[8]   <= q_m[8];
                        tmds_out[7:0] <= q_m[7:0];
                        cnt           <= cnt - $signed({1'b0, {~q_m[8], 1'b0}}) +
                                         $signed({1'b0, n1_qm}) - $signed({1'b0, n0_qm});
                    end
                end
            end
        end
    end

endmodule

// ============================================================
// Top-level: rgb2tmds — 3-channel TMDS encoder + serializer
// Targets Xilinx 7-Series (OSERDESE2, OBUFDS)
// ============================================================
module rgb2tmds #(
    parameter COLOR_DEPTH = 8   // Must be 8
)(
    input  wire        pclk,        // 25.175 MHz pixel clock
    input  wire        pclk_x5,    // 125.875 MHz (5× pclk) for OSERDESE2
    input  wire        rst_n,

    // VGA-style input from VGA controller
    input  wire [7:0]  rgb_in,      // RGB332 packed: [7:5]=R [4:2]=G [1:0]=B
    input  wire        hsync,
    input  wire        vsync,
    input  wire        video_active,

    // HDMI TMDS differential outputs (connect to OBUFDS in top-level or here)
    output wire        hdmi_clk_p,
    output wire        hdmi_clk_n,
    output wire        hdmi_d0_p,   // Blue channel
    output wire        hdmi_d0_n,
    output wire        hdmi_d1_p,   // Green channel
    output wire        hdmi_d1_n,
    output wire        hdmi_d2_p,   // Red channel
    output wire        hdmi_d2_n
);

    // Expand RGB332 → 8 bits per channel
    // R[7:5] → 8-bit: replicate MSBs
    wire [7:0] red   = {rgb_in[7:5], rgb_in[7:5], rgb_in[7:6]};
    wire [7:0] green = {rgb_in[4:2], rgb_in[4:2], rgb_in[4:3]};
    // B[1:0] → 8-bit: replicate
    wire [7:0] blue  = {rgb_in[1:0], rgb_in[1:0], rgb_in[1:0], rgb_in[1:0]};

    // TMDS encoded 10-bit words per channel
    wire [9:0] tmds_d0, tmds_d1, tmds_d2;

    // Channel 0 (Blue) carries sync on ctrl bits during blanking
    tmds_encoder enc_d0 (
        .clk      (pclk),
        .rst_n    (rst_n),
        .data_in  (blue),
        .ctrl_in  ({vsync, hsync}),
        .de       (video_active),
        .tmds_out (tmds_d0)
    );

    // Channel 1 (Green)
    tmds_encoder enc_d1 (
        .clk      (pclk),
        .rst_n    (rst_n),
        .data_in  (green),
        .ctrl_in  (2'b00),
        .de       (video_active),
        .tmds_out (tmds_d1)
    );

    // Channel 2 (Red)
    tmds_encoder enc_d2 (
        .clk      (pclk),
        .rst_n    (rst_n),
        .data_in  (red),
        .ctrl_in  (2'b00),
        .de       (video_active),
        .tmds_out (tmds_d2)
    );

    // -------------------------------------------------------------------
    // Serialization: 10:1 OSERDESE2 (Xilinx 7-Series)
    // SDR mode, DATA_WIDTH=10, DATA_RATE_OQ="DDR" at 5× pixel clock
    // The OSERDESE2 takes 10 parallel bits and serializes at 5× clock (DDR)
    // -------------------------------------------------------------------

    // Serialize each channel using two cascaded OSERDESE2 (master/slave)
    // for 10-bit width support
    wire tmds_d0_serial, tmds_d1_serial, tmds_d2_serial, tmds_clk_serial;

    // --- D0 (Blue) ---
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .SERDES_MODE    ("MASTER"),
        .TRISTATE_WIDTH (1)
    ) oser_d0_master (
        .OQ   (tmds_d0_serial),
        .OFB  (),
        .TQ   (), .TFB  (), .SHIFTOUT1(), .SHIFTOUT2(),
        .CLK  (pclk_x5), .CLKDIV(pclk),
        .D1(tmds_d0[0]), .D2(tmds_d0[1]), .D3(tmds_d0[2]), .D4(tmds_d0[3]),
        .D5(tmds_d0[4]), .D6(tmds_d0[5]), .D7(tmds_d0[6]), .D8(tmds_d0[7]),
        .SHIFTIN1(1'b0), .SHIFTIN2(1'b0),
        .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN(1'b0), .TCE(1'b0),
        .OCE(1'b1), .RST(~rst_n)
    );

    // --- D1 (Green) ---
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .SERDES_MODE    ("MASTER"),
        .TRISTATE_WIDTH (1)
    ) oser_d1_master (
        .OQ   (tmds_d1_serial),
        .OFB  (),
        .TQ   (), .TFB  (), .SHIFTOUT1(), .SHIFTOUT2(),
        .CLK  (pclk_x5), .CLKDIV(pclk),
        .D1(tmds_d1[0]), .D2(tmds_d1[1]), .D3(tmds_d1[2]), .D4(tmds_d1[3]),
        .D5(tmds_d1[4]), .D6(tmds_d1[5]), .D7(tmds_d1[6]), .D8(tmds_d1[7]),
        .SHIFTIN1(1'b0), .SHIFTIN2(1'b0),
        .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN(1'b0), .TCE(1'b0),
        .OCE(1'b1), .RST(~rst_n)
    );

    // --- D2 (Red) ---
    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .SERDES_MODE    ("MASTER"),
        .TRISTATE_WIDTH (1)
    ) oser_d2_master (
        .OQ   (tmds_d2_serial),
        .OFB  (),
        .TQ   (), .TFB  (), .SHIFTOUT1(), .SHIFTOUT2(),
        .CLK  (pclk_x5), .CLKDIV(pclk),
        .D1(tmds_d2[0]), .D2(tmds_d2[1]), .D3(tmds_d2[2]), .D4(tmds_d2[3]),
        .D5(tmds_d2[4]), .D6(tmds_d2[5]), .D7(tmds_d2[6]), .D8(tmds_d2[7]),
        .SHIFTIN1(1'b0), .SHIFTIN2(1'b0),
        .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN(1'b0), .TCE(1'b0),
        .OCE(1'b1), .RST(~rst_n)
    );

    // --- Clock channel: serialize a constant 1010101010 pattern ---
    wire [9:0] tmds_clk_pattern = 10'b0000011111;  // Standard TMDS clock pattern

    OSERDESE2 #(
        .DATA_RATE_OQ   ("DDR"),
        .DATA_RATE_TQ   ("SDR"),
        .DATA_WIDTH     (10),
        .SERDES_MODE    ("MASTER"),
        .TRISTATE_WIDTH (1)
    ) oser_clk_master (
        .OQ   (tmds_clk_serial),
        .OFB  (),
        .TQ   (), .TFB  (), .SHIFTOUT1(), .SHIFTOUT2(),
        .CLK  (pclk_x5), .CLKDIV(pclk),
        .D1(tmds_clk_pattern[0]), .D2(tmds_clk_pattern[1]),
        .D3(tmds_clk_pattern[2]), .D4(tmds_clk_pattern[3]),
        .D5(tmds_clk_pattern[4]), .D6(tmds_clk_pattern[5]),
        .D7(tmds_clk_pattern[6]), .D8(tmds_clk_pattern[7]),
        .SHIFTIN1(1'b0), .SHIFTIN2(1'b0),
        .T1(1'b0), .T2(1'b0), .T3(1'b0), .T4(1'b0),
        .TBYTEIN(1'b0), .TCE(1'b0),
        .OCE(1'b1), .RST(~rst_n)
    );

    // -------------------------------------------------------------------
    // Differential output buffers (OBUFDS)
    // -------------------------------------------------------------------
    OBUFDS #(.IOSTANDARD("TMDS_33")) obuf_clk (.I(tmds_clk_serial), .O(hdmi_clk_p), .OB(hdmi_clk_n));
    OBUFDS #(.IOSTANDARD("TMDS_33")) obuf_d0  (.I(tmds_d0_serial),  .O(hdmi_d0_p),  .OB(hdmi_d0_n));
    OBUFDS #(.IOSTANDARD("TMDS_33")) obuf_d1  (.I(tmds_d1_serial),  .O(hdmi_d1_p),  .OB(hdmi_d1_n));
    OBUFDS #(.IOSTANDARD("TMDS_33")) obuf_d2  (.I(tmds_d2_serial),  .O(hdmi_d2_p),  .OB(hdmi_d2_n));

endmodule

`default_nettype wire
