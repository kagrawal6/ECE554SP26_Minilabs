module baud_generator(
  input clk,
  input rst,
  input [7:0] divisor,
  input [1:0] ioaddr,
  output spart_enable
);

// internal signals
wire databus_high, databus_low;
wire zero;

// flops
reg [15:0] divisor_buffer_ff; 
reg [15:0] divisor_ff;


assign databus_high = (ioaddr == 2'b11);
assign databus_low  = (ioaddr == 2'b10);

assign zero = divisor_ff == 16'b0;
assign spart_enable = zero;


always @(posedge clk, posedge rst) begin
  if(rst)
    divisor_ff <= 16'b0;
  else if(zero)
    divisor_ff <= divisor_buffer_ff;
  else
    divisor_ff <= divisor_ff - 1;
end

always @(posedge clk, posedge rst)
  if(rst)
    divisor_buffer_ff <= 16'b0;
  else if (databus_low)
    divisor_buffer_ff <= {divisor_buffer_ff[15:8], divisor};
  else if (databus_high)
    divisor_buffer_ff <= {divisor, divisor_buffer_ff[7:0]};

endmodule