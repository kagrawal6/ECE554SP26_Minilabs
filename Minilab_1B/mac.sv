module MAC #
(
  parameter DATA_WIDTH = 8
)
(
  input clk,
  input rst_n,
  input En,
  input Clr,
  input [DATA_WIDTH-1:0] Ain,
  input [DATA_WIDTH-1:0] Bin,
  output [DATA_WIDTH*3-1:0] Cout
);

  // -------------------------------------------------------
  //  Pipeline Stage 0: Register inputs
  //  Breaks the FIFO-output-register → multiplier path
  // -------------------------------------------------------
  reg [DATA_WIDTH-1:0] ain_reg;
  reg [DATA_WIDTH-1:0] bin_reg;
  reg en_d0;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      ain_reg <= {DATA_WIDTH{1'b0}};
      bin_reg <= {DATA_WIDTH{1'b0}};
      en_d0   <= 1'b0;
    end
    else begin
      ain_reg <= Ain;
      bin_reg <= Bin;
      en_d0   <= En;
    end
  end

  // -------------------------------------------------------
  //  Pipeline Stage 1: Multiply (register the product)
  // -------------------------------------------------------
  reg [DATA_WIDTH*2-1:0] product_reg;
  reg en_d1;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      product_reg <= {(DATA_WIDTH*2){1'b0}};
      en_d1       <= 1'b0;
    end
    else begin
      product_reg <= ain_reg * bin_reg;
      en_d1       <= en_d0;
    end
  end

  // -------------------------------------------------------
  //  Pipeline Stage 2: Accumulate (using registered product)
  // -------------------------------------------------------
  reg [DATA_WIDTH*3-1:0] accumulator;

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      accumulator <= {(DATA_WIDTH*3){1'b0}};
    end
    else if (Clr) begin
      accumulator <= {(DATA_WIDTH*3){1'b0}};
    end
    else if (en_d1) begin
      accumulator <= accumulator + product_reg;
    end
  end

  // Output the accumulator value
  assign Cout = accumulator;

endmodule
