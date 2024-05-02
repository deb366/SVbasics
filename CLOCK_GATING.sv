//Forward clock gating 
// Forward Clock Gating design implementation with external gating control
module ForwardClockGating (
    input logic clk,            // System clock
    input logic rst_n,          // Active low reset
    input logic [7:0] data_in,  // Data input
    input logic enable_gate,    // External gating signal
    output logic [7:0] data_out // Data output
);

    // Gated clock signal
    logic gated_clk;

    // Generating the gated clock based on external gating signal
    assign gated_clk = clk & enable_gate;

    // Register for actual data output
    // Updates based on the gated clock, which is controlled by external gating signal
    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 0;  // Reset data output to zero
        else
            data_out <= data_in;  // Pass the input data to output on gated clock edge
    end

endmodule


//Backward clock gating - Here the gating signal is internally generated 

module BackwardClockGating (
    input logic clk,        // System clock
    input logic rst_n,      // Active low reset
  input logic [7:0] data_in,    // Data input
  output logic [7:0] data_out   // Data output
);

    // Internal register to hold previous data_out state
  logic [7:0] prev_data_out;
    // Gated clock signal
    logic gated_clk;

    // Determine if data_out has changed
    logic data_changed;
    assign data_changed = (data_out != prev_data_out);

    // Clock gating control based on data change and input change
    // This ensures the clock is gated only when there are no expected changes
    assign gated_clk = clk & (data_changed | (data_in != data_out));

    // Register for actual data output
    // This register updates based on the gated clock,
    // which is controlled by data changes and input differences
    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 0;
        else
            data_out <= data_in;
    end

    // Register to capture previous data_out value
    // It is crucial this register is updated every cycle to accurately compare
    // changes in data_out for correct gating decision.
    // Therefore, it remains driven by the main clock, 'clk'.
  always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n)
            prev_data_out <= 0;
        else
            prev_data_out <= data_out;
    end

endmodule
