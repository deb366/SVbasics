

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
    else if (r_current == 1) begin
      o_valid <= 1;                      // Assert valid when computation completes
    end
  end

  assign o_data = r_data;                // Assign result to output

endmodule
