module conv2d (
    input iCLK,
    input iRST,
    input [11:0] iDATA,
    input iDVAL,
    output [11:0] oRed,
    output [11:0] oGreen,
    output [11:0] oBlue,
    output oDVAL,
    input [15:0] iX_Cont,       // Fix #8: widened to 16 bits to match top-level
    input [15:0] iY_Cont,
    input [1:0]  iMode          // 00=|Gx|+|Gy|, 01=|Gx| only, 10=|Gy| only, 11=greyscale
);

logic [11:0] mDATA_0, mDATA_1;
logic [11:0] mDATAd_0, mDATAd_1;
logic [13:0] gray, gray_scale;
logic mDVAL;

logic [11:0] gray_pixel;

logic [15:0] mag;
logic sobel_valid;

assign gray_pixel = gray_scale[13:2];

// ---- Bayer row line buffer (1280 deep, 2 taps, 12-bit) ----
Line_Buffer1 u0(
    .clken(iDVAL),
    .clock(iCLK),
    .shiftin(iDATA),
    .taps0x(mDATA_1),
    .taps1x(mDATA_0)
);

// ---- Stage 1: Bayer-to-greyscale (2x2 average) + decimation ----
always @(posedge iCLK or negedge iRST) begin
    if (!iRST) begin
        gray_scale <= 0;
        mDATAd_0 <= 0;
        mDATAd_1 <= 0;
        mDVAL <= 0;
    end else begin
        mDATAd_0 <= mDATA_0;
        mDATAd_1 <= mDATA_1;
        mDVAL <= (iY_Cont[0] | iX_Cont[0]) ? 1'b0 : iDVAL;
        gray_scale <= (mDATA_0 + mDATA_1 + mDATAd_0 + mDATAd_1);
    end
end

// ---- Greyscale row line buffer (640 deep, 3 taps, 12-bit) ----
// NOTE: LineBuffer2 must have tap_distance=640 (Fix #3)
logic [11:0] tap0, tap1, tap2;

LineBuffer2 u1(
    .clken(mDVAL),
    .clock(iCLK),
    .shiftin(gray_pixel),
    .taps0x(tap2),          // 1 row back
    .taps1x(tap1),          // 2 rows back
    .taps2x(tap0)           // 3 rows back
);

// ---- Stage 2: 3x3 window construction ----
logic [11:0] a00, a01, a02;
logic [11:0] a10, a11, a12;
logic [11:0] a20, a21, a22;

always @(posedge iCLK or negedge iRST) begin
    if (!iRST) begin
        {a00,a01,a02} <= 0;
        {a10,a11,a12} <= 0;
        {a20,a21,a22} <= 0;
    end else if (mDVAL) begin
        a00 <= tap2;  a01 <= a00;  a02 <= a01;
        a10 <= tap1;  a11 <= a10;  a12 <= a11;
        a20 <= tap0;  a21 <= a20;  a22 <= a21;
    end
end

// ---- Stage 3: Sobel convolution (combinational) ----
wire signed [15:0] Gy = -$signed({1'b0,a00}) - 2*$signed({1'b0,a10}) - $signed({1'b0,a20})
                         + $signed({1'b0,a02}) + 2*$signed({1'b0,a12}) + $signed({1'b0,a22});

wire signed [15:0] Gx = -$signed({1'b0,a00}) - 2*$signed({1'b0,a01}) - $signed({1'b0,a02})
                         + $signed({1'b0,a20}) + 2*$signed({1'b0,a21}) + $signed({1'b0,a22});

// Fix #1: magnitude = |Gx| + |Gy| (was only |Gy|)
wire [15:0] abs_Gx = Gx[15] ? -Gx : Gx;
wire [15:0] abs_Gy = Gy[15] ? -Gy : Gy;

// Mode select: 00=both, 01=horiz(|Gx|), 10=vert(|Gy|), 11=greyscale passthrough
always_comb begin
    case (iMode)
        2'b00:   mag = abs_Gx + abs_Gy;        // combined edges
        2'b01:   mag = abs_Gx;                  // horizontal edges only
        2'b10:   mag = abs_Gy;                  // vertical edges only
        2'b11:   mag = {4'b0, gray_pixel};      // greyscale passthrough
        default: mag = abs_Gx + abs_Gy;
    endcase
end

// Fix #6: Saturate to 12 bits (prevents wrap-around for strong edges)
wire [11:0] mag_sat = (|mag[15:12]) ? 12'hFFF : mag[11:0];

// ---- Fix #2: Valid signal properly tracks mDVAL (no longer stuck high) ----
always @(posedge iCLK or negedge iRST) begin
    if (!iRST)
        sobel_valid <= 0;
    else
        sobel_valid <= mDVAL;   // pulses HIGH for 1 cycle per valid pixel
end

// ---- Fix #7: Border pixel detection using output pixel counters ----
logic [9:0] out_col, out_row;
wire is_border;

always @(posedge iCLK or negedge iRST) begin
    if (!iRST) begin
        out_col <= 0;
        out_row <= 0;
    end else if (sobel_valid) begin
        if (out_col == 639) begin
            out_col <= 0;
            out_row <= (out_row == 479) ? 0 : out_row + 1;
        end else begin
            out_col <= out_col + 1;
        end
    end
end

// Zero the first/last 2 rows and first/last 2 columns where 3x3 window is incomplete
assign is_border = (out_col < 2) || (out_col > 637) || (out_row < 2) || (out_row > 477);

// ---- Output: saturated magnitude, zeroed at borders ----
wire [11:0] pixel_out = is_border ? 12'd0 : mag_sat;

assign oRed   = pixel_out;
assign oGreen = pixel_out;
assign oBlue  = pixel_out;
assign oDVAL  = sobel_valid;

endmodule
