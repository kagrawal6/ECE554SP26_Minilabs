`timescale 1ns/1ps

module testbench_tb;

  // Clock and reset
  reg clk;
  reg rst_n;
  
  // Inputs to DUT
  reg [9:0] SW;
  reg [3:0] KEY;
  
  // Outputs from DUT
  wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  wire [9:0] LEDR;

  // Expected 7-segment patterns (accent-low, accent-high for lit segment)
  parameter [6:0] SEG_0 = 7'b1000000;
  parameter [6:0] SEG_1 = 7'b1111001;
  parameter [6:0] SEG_5 = 7'b0010010;
  parameter [6:0] SEG_8 = 7'b0000000;
  parameter [6:0] SEG_B = 7'b0000011;  // 11 in hex = B

  // Instantiate the DUT (Device Under Test)
  Minilab0 dut (
    .CLOCK_50(clk),
    .CLOCK2_50(clk),
    .CLOCK3_50(clk),
    .CLOCK4_50(clk),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .LEDR(LEDR),
    .KEY(KEY),
    .SW(SW)
  );

  // Clock generation: 50 MHz = 20ns period
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize inputs
    SW = 10'b0;
    KEY = 4'b1111;  // All keys released (active low)
    
    // Apply reset (KEY[0] is active low reset)
    KEY[0] = 1'b0;
    #100;
    KEY[0] = 1'b1;  // Release reset
    
    // Wait for state machine to complete
    // FILL state: 8 cycles to fill FIFO
    // EXEC state: 8 cycles to process
    // Then DONE state
    #500;
    
    // Turn on SW[0] to display result
    SW[0] = 1'b1;
    
    // Wait and observe
    #200;
    
    // =========================================
    // TEST 1: Check if we're in DONE state
    // =========================================
    $display("\n=== TEST 1: State Machine ===");
    if (LEDR[1:0] == 2'd2) begin
      $display("PASS: State machine reached DONE state (state = %d)", LEDR[1:0]);
    end
    else begin
      $display("FAIL: State machine did not reach DONE state");
      $display("      Current state (LEDR[1:0]) = %d", LEDR[1:0]);
    end
    
    // =========================================
    // TEST 2: Check if LED1 is ON (DONE indicator)
    // =========================================
    $display("\n=== TEST 2: LED1 DONE Indicator ===");
    if (LEDR[1] == 1'b1) begin
      $display("PASS: LED1 is ON indicating DONE state");
    end
    else begin
      $display("FAIL: LED1 is not ON");
    end
    
    // =========================================
    // TEST 3: Verify 7-segment display output
    // Expected: 001B58 (hex) = 7000 (decimal)
    // =========================================
    $display("\n=== TEST 3: 7-Segment Display (Expected: 001B58) ===");
    $display("HEX5 = %b (expected %b for '0')", HEX5, SEG_0);
    $display("HEX4 = %b (expected %b for '0')", HEX4, SEG_0);
    $display("HEX3 = %b (expected %b for '1')", HEX3, SEG_1);
    $display("HEX2 = %b (expected %b for 'B')", HEX2, SEG_B);
    $display("HEX1 = %b (expected %b for '5')", HEX1, SEG_5);
    $display("HEX0 = %b (expected %b for '8')", HEX0, SEG_8);
    
    if (HEX5 == SEG_0 && HEX4 == SEG_0 && HEX3 == SEG_1 &&
        HEX2 == SEG_B && HEX1 == SEG_5 && HEX0 == SEG_8) begin
      $display("PASS: 7-segment display shows correct value 001B58");
    end
    else begin
      $display("FAIL: 7-segment display does not match expected value");
    end
    
    // =========================================
    // TEST 4: Verify MAC output value directly
    // =========================================
    $display("\n=== TEST 4: MAC Output Value ===");
    $display("Expected dot product: 7000 (0x1B58)");
    $display("MAC output (macout) = %d (0x%h)", dut.macout, dut.macout);
    
    if (dut.macout == 24'd7000) begin
      $display("PASS: MAC output is correct (7000)");
    end
    else begin
      $display("FAIL: MAC output is incorrect");
      $display("      Expected: 7000, Got: %d", dut.macout);
    end
    
    // =========================================
    // Summary
    // =========================================
    $display("\n=== SIMULATION COMPLETE ===");
    $display("Dot product of arrays:");
    $display("  Array 1: [0, 5, 10, 15, 20, 25, 30, 35]");
    $display("  Array 2: [0, 10, 20, 30, 40, 50, 60, 70]");
    $display("  Result:  7000 (0x1B58)");
    
    #100;
    $finish;
  end

  // Monitor state changes
  initial begin
    $monitor("Time=%0t | State=%d | SW[0]=%b | LEDR=%b", 
             $time, LEDR[1:0], SW[0], LEDR);
  end

endmodule
