module spart_tx(
  input clk,
  input rst,
  input enable,
  input shift_enable,
  input [7:0] tx_bus,
  output txd,
  output reg tbr
);

  ////////////////////////////////////////
  //       States for Control SM       //
  //////////////////////////////////////
  typedef enum reg 
  {
      IDLE, 
      TRANSMIT
  } state_t;

  state_t state, nxt_state;

  //////////////////////////////////////////
  //          INTERNAL SIGNALS           //
  ////////////////////////////////////////
  reg [8:0]  tx_shft_reg;
  reg [3:0]  bit_cnt;
  reg        init, transmitting, set_done, tx_done_ff;
  wire       shift;

  assign   txd = tx_shft_reg[0];
  assign   tbr = tx_done_ff;
  assign shift = shift_enable & transmitting;

  ///////////////////////////////////////////////
  //         Control SM's output logic        //
  /////////////////////////////////////////////
  always_comb
  begin
    // Default outputs
    init = 0;
    transmitting = 0;
    set_done = 0;
    nxt_state = state;
    case (state)
      IDLE:
        // prepare to transmit data now!
        if (enable) 
        begin
          init = 1;
          transmitting = 1;
          nxt_state = TRANSMIT;
        end
       // TRASMIT DATA NOW!
      TRANSMIT:
        // transition to idle after 10 shifts
        if (bit_cnt == 10)
        begin
          // producer done
          set_done = 1;
          // next, we spin
          nxt_state = IDLE;
        end
        // o.w. transmit next bit
        else
        begin
          init = 0;
          transmitting = 1;
        end
     // Livin' on a prayer
      default:
        nxt_state = IDLE;
    endcase
  end

  //////////////////////////////////////////
  //           Control SM's FF           //
  ////////////////////////////////////////
  always_ff @(posedge clk, posedge rst)
    if (!rst_n)     // RST
      state <= IDLE;
    else            // NXT
      state <= nxt_state;

  ////////////////////////////////////////
  //       TRANSMIT DONE RS FLOP       //
  //////////////////////////////////////
  always_ff @(posedge clk, posedge rst_n)
    if (!rst_n)        // RST
      tx_done_ff <= 1'b0;
    else if (set_done) // SET
      tx_done_ff <= 1'b1;
    else if (init)     // RST
      tx_done_ff <= 1'b0;

  ////////////////////////////////
  //     BIT COUNT REGISTER    //
  //////////////////////////////
  always @(posedge clk)
    if (init)       // RST
      bit_cnt <= 3'b0;
    else if (shift) // INC
      bit_cnt <= bit_cnt + 1;

  ////////////////////////////////////////////////
  //              SHIFT REGISTER               //
  //////////////////////////////////////////////
  always @(posedge clk, posedge rst_n)
    if (!rst_n)     // PRE
      tx_shft_reg <= 9'b1;
    else if (init)  // accept new val
      tx_shft_reg <= {tx_bus, 1'b0};
    else if (shift) // shift
      tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};

endmodule