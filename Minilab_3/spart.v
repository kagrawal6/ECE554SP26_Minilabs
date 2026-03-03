//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
  input clk,
  input rst,
  input iocs,
  input iorw,
  output rda,
  output tbr,
  input [1:0] ioaddr,
  inout [7:0] databus,
  output txd,
  input rxd
);

wire spart_enable;

wire [7:0] tx_bus;
wire [7:0] rx_bus;


// module instantiations
bus_interface bus(
  .iocs(iocs),
  .iorw(iorw),
  .rda(rda),
  .tbr(tbr),
  .ioaddr(ioaddr),
  .rxd(rx_bus),
  .databus(databus),
  .txd(tx_bus),
  .tx_enable(tx_enable),
  .rx_enable(rx_enable)
  );


baud_generator BGR(
  .clk(clk),
  .rst(rst),
  .divisor(tx_bus),
  .ioaddr(ioaddr),
  .spart_enable(shift_enable)
);

spart_tx tx(
  .clk(clk),
  .rst(rst),
  .enable(tx_enable),
  .shift_enable(shift_enable),
  .ioaddr(ioaddr),
  .tx_bus(tx_bus),
  .txd(txd),
  .tbr(tbr)
);

spart_rx rx(
  .clk(clk),
  .rst(rst),
  .enable(rx_enable),
  .shift_enable(shift_enable),
  .ioaddr(ioaddr),
  .rx_bus(rx_bus),
  .rxd(rxd),
  .rda(rda)
);

endmodule
