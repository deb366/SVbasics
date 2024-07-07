//Accumulator 
//Design a simple FSM where the input is I_VALUE 4bit number and I_VALID, the I_VALUE will be accumulated until it gets a I_TERM signal to 
//GIVE the accumulated output(O_SUM) and O_DONE signal 

module ACCUM(
    input logic clk,
    input logic rstn,
    input logic I_VALID,
    input logic I_TERM,  
    input logic [3:0] I_VALUE,
    //output logic [7:0] O_ACCUM,  // Fixed: Specify output signal name
  output logic [7:0] O_SUM,
    output logic O_DONE
);
  
  logic [7:0] r_count;
  always_ff @(posedge clk)begin 
    if(!rstn)
      r_count <= '0;
    else if(O_DONE)begin 
      r_count <= '0;
      O_DONE <= '0;
    end 
    else if (I_VALID && |I_VALUE)
      r_count <= r_count + I_VALUE;
    else if(I_TERM) begin 
      O_DONE <= 1;
    end 
  end 
  
  assign O_SUM = r_count;
endmodule 

//++++++++++++++++++++++++++++++++//
//Test bench 
//++++++++++++++++++++++++++++++++//
`timescale 1ns/1ps

module tb_ACCUM;

    // Testbench variables
    logic clk, rstn, I_VALID, I_TERM;
    logic [3:0] I_VALUE;
    logic [7:0]  O_SUM;
    logic O_DONE;

    // Instantiate the Accumulator module
    ACCUM uut(
        .clk(clk),
        .rstn(rstn),
        .I_VALID(I_VALID),
        .I_TERM(I_TERM),
        .I_VALUE(I_VALUE),
       // .O_ACCUM(O_ACCUM),  // Corrected output name
        .O_SUM(O_SUM),
        .O_DONE(O_DONE)
    );

    // Clock generation
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Initial setup and stimulus
    initial begin
        // Initialize inputs
        rstn = 0;
        I_VALID = 0;
        I_TERM = 0;
        I_VALUE = 0;

        // Release reset
        @(posedge clk) rstn = 1;
        @(posedge clk);

        // Simulate input value accumulations
        @(posedge clk) begin
            I_VALID = 1;
            I_VALUE = 4;
        end
        @(posedge clk) I_VALUE = 3; // Accumulate more
        @(posedge clk) I_VALUE = 2; // And more

        // Test reset accumulation by TERM signal
        @(posedge clk) begin
            I_TERM = 1; // Signal termination to reset and set O_DONE
            I_VALID = 0;
        end

        // Observe O_DONE signal
        @(posedge clk) begin
            I_TERM = 0; // Clear termination signal
        end
        
        // Test additional behavior after reset
        @(posedge clk) begin
            I_VALID = 1;
            I_VALUE = 5; // Add new value
        end
        @(posedge clk) I_VALUE = 1; // Continue accumulating

        // End of test
        repeat (5) @(posedge clk);
        $stop; // Stop the simulation
    end

    // Monitor Outputs
    initial begin
        $monitor("Time=%t, rstn=%b, I_VALID=%b, I_VALUE=%b, O_SUM=%b, O_DONE=%b", 
                 $time, rstn, I_VALID, I_VALUE, O_SUM, O_DONE);
    end
  initial begin 
    $dumpvars;
  end 

endmodule
