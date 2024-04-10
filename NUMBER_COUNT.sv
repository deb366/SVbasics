/*
The module will take 8bit input , and gives 32bit output the output is the total count of the specific input number and the number itself.
	Sol:
	We need a [255:0][7:0] RAM for this, at the very next clk of input change the RAM's input position will be added with 1. At the next clk the RAM's updated position will be read to give the output. 
*/
	module count_numbers(
	  input logic clk,rstn,
	  input logic [7:0] I_NUM,
	  output logic [7:0] O_NUM,
	  output logic [7:0] O_CNT
	);
	  
	  logic [255:0][7:0] r_ram;
	  logic [7:0] r_inum;
	  
	  always_ff @(posedge clk)begin 
	    if(!rstn)begin 
	      r_ram <= '0;
	      r_inum <= '0;
	    end
	    
	    else begin 
	      r_ram[I_NUM] <= r_ram[I_NUM] + 1'b1;
	      r_inum <= I_NUM;      
	    end    
	  end
	  
	  assign O_NUM = r_inum;
	  assign O_CNT = r_ram[r_inum];
	  
	  
	endmodule 
