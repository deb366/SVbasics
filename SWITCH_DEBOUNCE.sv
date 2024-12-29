/* Switch debounce rtl logic for proper switching detection and debounce duration of 10ns
Problem breakdown: The design basically needs the output to take the input(stayed constant for DEBOUNCE_PERIOD). The output willl not take the input value if the input changes before the DEBOUNCE_PERIOD.  
*/

module SWITCH_DEBOUNCE #(
    parameter DEBOUNCE_PERIOD = 30,  // 10ns debounce period
    parameter CLOCK_FREQ = 1000000 // Assuming 100MHz clock
)(
    input wire clk,          // System clock
    input wire rst_n,        // Active low reset
    input wire switch_in,    // Raw input from mechanical switch
    output reg switch_out    // Debounced switch output
);

    // Calculate counter width based on clock frequency and debounce period
    // Counter_width = ceil(log2(CLOCK_FREQ * DEBOUNCE_PERIOD / 1e9))
    localparam COUNTER_WIDTH = 16;  // For 10ns at 100MHz we need very few bits
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam CHECK_BOUNCE = 2'b01;
    localparam WAIT_STABLE = 2'b10;
    
    // Internal registers
    reg [1:0] current_state, next_state;
    reg [COUNTER_WIDTH-1:0] counter;
    reg switch_sync1, switch_sync2; // Double flopping for metastability
    wire switch_sync;
    
    // Double flop synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_sync1 <= 1'b0;
            switch_sync2 <= 1'b0;
        end else begin
            switch_sync1 <= switch_in;
            switch_sync2 <= switch_sync1;
        end
    end
    
    assign switch_sync = switch_sync2;
    
    // State and counter registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            counter <= 0;
        end else begin
            current_state <= next_state;
            if (current_state == CHECK_BOUNCE) begin
                counter <= counter + 1;
            end else begin
                counter <= 0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (switch_sync != switch_out)
                    next_state = CHECK_BOUNCE;
            end
            
            CHECK_BOUNCE: begin
                if (switch_sync != switch_out) begin
                    if (counter == (DEBOUNCE_PERIOD-1))
                        next_state = WAIT_STABLE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            WAIT_STABLE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_out <= 1'b0;
        end else if (current_state == WAIT_STABLE) begin
            switch_out <= switch_sync;
        end
    end

endmodule

//-------------------Testbench--------------//
// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module switch_debounce_tb();

    // Parameters
    localparam DEBOUNCE_PERIOD = 30;  // Debounce period (10 clock cycles)
    localparam CLOCK_FREQ = 100000000; // Clock frequency (100 MHz)
    
    // Inputs
    reg clk;
    reg rst_n;
    reg switch_in;

    // Outputs
    wire switch_out;

    // Instantiate the DUT (Device Under Test)
    SWITCH_DEBOUNCE #(
        .DEBOUNCE_PERIOD(DEBOUNCE_PERIOD),
        .CLOCK_FREQ(CLOCK_FREQ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .switch_in(switch_in),
        .switch_out(switch_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10 ns period)
    end

    // Stimulus
    initial begin
        // Reset the system
        rst_n = 0;
        switch_in = 0;
        #20 rst_n = 1; // Deassert reset after 20 ns

        // Simulate bouncing
        #30 switch_in = 1; // Switch press
        #15 switch_in = 0; // Bounce
        #15 switch_in = 1; // Bounce
        #50 switch_in = 1; // Stable high
        
        #100 switch_in = 1; // Switch release
        #200 switch_in = 1; // Bounce
        #20 switch_in = 0; // Bounce
        #50 switch_in = 0; // Stable low

        // End simulation
        #200 $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0t | rst_n: %b | switch_in: %b | switch_out: %b", 
                 $time, rst_n, switch_in, switch_out);
    end
  initial begin 
    $dumpvars;
  end 

endmodule

