// Code your design here


module FIBONACCII(input logic clk,rstn,output logic [7:0] w_sum);
  logic [7:0] r_a0,r_a1;

  
  always_ff @(posedge clk)begin 
    if(!rstn) begin 
      r_a0 <= 8'd0;
      r_a1 <= 8'd1;
    end 
    else begin  
      r_a0 <= r_a1;
      r_a1 <= r_a1 + r_a0;    	
    end 
  end 
  
  assign w_sum = r_a0 + r_a1;
endmodule 

//+++++++++++++++++++++++++++++++++//
//2 output at the same time
//+++++++++++++++++++++++++++++++++//
module FIBONACCII(input logic clk,rstn,output logic [7:0] r_a1, r_a0);
 // logic [7:0] r_a0,r_a1;

  
  always_ff @(posedge clk)begin 
    if(!rstn) begin 
      r_a0 <= 8'd0;
      r_a1 <= 8'd1;
    end 
    else begin  
      r_a0 <= r_a0+r_a1;
      r_a1 <= r_a0+r_a1 + r_a1;    	
    end 
  end 
  
  //assign w_sum = r_a0 + r_a1;
endmodule 


//+++++++++++++++++++++++++++++++++//
//4 output at the same time
//+++++++++++++++++++++++++++++++++//
module FIBONACCII(input logic clk,rstn,output logic [15:0] r_a3, r_a2,r_a1, r_a0);
 // logic [7:0] r_a0,r_a1;

  
  always_ff @(posedge clk)begin 
    if(!rstn) begin 
      r_a0 <= 8'd0;
      r_a1 <= 8'd1;
      r_a2 <= 8'd1;
      r_a3 <= 8'd2;      
    end 
    else begin  
      r_a0 <= r_a2+r_a3;     //r_a2+r_a3 
      r_a1 <= r_a2+2*r_a3;  //r_a2+r_a3 + r_a3
      r_a2 <= 2*r_a2+3*r_a3;//r_a2+r_a3 + r_a3 + r_a2+r_a3
      r_a3 <= 3*r_a2+5*r_a3;//r_a2+r_a3 + r_a3 + r_a2+r_a3 + r_a2+r_a3 + r_a3
    end 
  end 
  
  //assign w_sum = r_a0 + r_a1;
endmodule 
