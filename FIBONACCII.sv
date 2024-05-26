// Code your design here


module FIBONACCII(input logic clk,rstn,output logic [7:0] w_sum);
  logic [7:0] r_a0,r_a1;

  
  always_ff @(posedge clk)begin 
    if(!rstn) begin 
      r_a0 <= 8'd1;
      r_a1 <= '0;
    end 
    else begin  
      r_a0 <= w_sum;
      r_a1 <= r_a0;    	
    end 
  end 
  
  assign w_sum = r_a0 + r_a1;
endmodule 
