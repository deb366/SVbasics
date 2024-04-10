//Input is 8bit, find the mod 5 (i.e input % 5) of the input using combinational logic .
	
	// Code your design here
	module Mod5Calculator(
	    input logic [7:0] input_data,
	    output logic [2:0] mod_5_value
	);
	
	always_comb begin
	    // Initialize the result to the input value
	    logic [7:0] result = input_data;
	    
	    // Perform iterative subtraction until the result is less than 5
	    while (result >= 5) begin
	        result = result - 5;
	    end
	    
	    // Assign the result as the modulo 5 value
	    mod_5_value = result;
	end
	
	endmodule
