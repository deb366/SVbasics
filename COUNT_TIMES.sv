// 57.	Design a parameterized (N is the max count) logic where each clock will generate the output like (0,1,2,2,3,3,3,4,4,4,4,…,N with N times)? 
//WIP


// Code your design here


module COUNT_TIMES #(parameter N =4) (input logic clk,rstn, output logic [$clog2(N)-1:0] O_COUNT);
  
  localparam N0 = $clog2(N);  // Number of bits to count up to N
  logic [N0-1:0] r_times;
  logic  w_next;

always_ff @(posedge clk)begin 
  if(!rstn) O_COUNT <= 'h0;
  else begin 
    if(w_next) begin 
    	O_COUNT <= O_COUNT + 1;
      	r_times <= 'h0;
    end 
    else begin 
      O_COUNT <= O_COUNT;
      //r_times <= r_times + 1;
    end 
  end 
end 

assign w_next = r_times == O_COUNT;
  
endmodule
