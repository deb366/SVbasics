
module FACTORIAL_N (
  input  logic clk,                      // Clock signal
  input  logic rstn,                     // Active-low reset signal
  input  logic i_load,                   // Load signal
  input  logic [3:0] n,                  // Input number (4-bit to support up to 15)
  output logic [31:0] o_data,            // Output data (factorial, supports up to 12!)
  output logic o_valid                   // Output valid flag
);

  logic [31:0] r_data;                   // Register to store intermediate results
  logic [3:0] r_current;                 // Register to store current countdown value

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      r_data <= 0;                       // Reset r_data to 0
      r_current <= 0;                    // Reset r_current to 0
      o_valid <= 0;                      // Reset o_valid to 0
    end 
    else if (i_load) begin
      r_data <= 1;                       // Initialize factorial result
      r_current <= n;                    // Load input n into r_current
      o_valid <= 0;                      // Clear valid signal during computation
    end 
    else if (r_current > 1) begin
      r_data <= r_data * r_current;      // Multiply by current value
      r_current <= r_current - 1;        // Decrement current value
    end 
    else if (r_current == 0) begin
      r_data <= 1;      // Multiply by current value
      o_valid <= 1;
      //r_current <= r_current - 1;        // Decrement current value
    end     
    else if (r_current == 1) begin
      o_valid <= 1;                      // Assert valid when computation completes
    end
  end

  assign o_data = r_data;                // Assign result to output

endmodule



//---------- Testbench ------------//
module FACTORIAL_N_tb;

  // Testbench signals
  logic clk;
  logic rstn;
  logic i_load;
  logic [3:0] n;
  logic [31:0] o_data;
  logic o_valid;

  // Instantiate the DUT (Device Under Test)
  FACTORIAL_N dut (
    .clk(clk),
    .rstn(rstn),
    .i_load(i_load),
    .n(n),
    .o_data(o_data),
    .o_valid(o_valid)
  );

  // Clock generation (50% duty cycle)
  always #5 clk = ~clk;

  // Test procedure
  initial begin
    // Initialize signals
    clk = 0;
    rstn = 0;
    i_load = 0;
    n = 0;

    // Apply reset
    $display("Applying reset...");
    #10 rstn = 1; // Release reset
    #10;

    // Test case 1: n = 5
    $display("Testing n = 5...");
    i_load = 1;
    n = 5;
    #10 i_load = 0; // Deassert load
    wait(o_valid);  // Wait for computation to complete
    $display("n = 5, Factorial = %0d, o_valid = %b", o_data, o_valid);
    #10;

    // Test case 2: n = 0 (special case)
    $display("Testing n = 0...");
    i_load = 1;
    n = 0;
    #10 i_load = 0; // Deassert load
    wait(o_valid);  // Wait for computation to complete
    $display("n = 0, Factorial = %0d, o_valid = %b", o_data, o_valid);
    #10;
    
   // Test case 3: n = 4
    $display("Testing n = 4...");
    i_load = 1;
    n = 4;
    #10 i_load = 0; // Deassert load
    wait(o_valid);  // Wait for computation to complete
    $display("n = 4, Factorial = %0d, o_valid = %b", o_data, o_valid);
    #10;

    // Test case 4: n = 10 (to check bit-width handling)
    $display("Testing n = 10...");
    i_load = 1;
    n = 10;
    #10 i_load = 0; // Deassert load
    wait(o_valid);  // Wait for computation to complete
    $display("n = 10, Factorial = %0d, o_valid = %b", o_data, o_valid);
    #10;
    

    // Finish simulation
    $display("Testbench completed.");
    $stop;
  end
endmodule

