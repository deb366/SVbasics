// 57.	Design a parameterized (N is the max count) logic where each clock will generate the output like (0,1,2,2,3,3,3,4,4,4,4,…,N with N times)? 


module COUNT_TIMES #(
    parameter N = 32,           // Declare N here, I_TIMES <= 2^32 -1
    localparam N0 = $clog2(N)   // Then declare N0 using N
) (
    input logic clk, rstn,
  input logic [N0-1:0] I_TIMES,
  output logic [N0-1:0] O_COUNT,
  output logic O_END
); // Number of bits to count up to N
  
  logic [N0-1:0] r_times;
  logic  w_next;

always_ff @(posedge clk)begin 
  if(!rstn || O_END) begin O_COUNT <= 'h0; r_times <= 'h0; end 
  else begin 
    if(w_next) begin 
    	O_COUNT <= O_COUNT + 1;
      	r_times <= 1;
    end 
    else begin 
      O_COUNT <= O_COUNT;
      r_times <= r_times + 1;
    end 
  end 
end 

  //assign w_next = (r_times == O_COUNT) && |O_COUNT && (r_times == (O_COUNT -1));
  assign w_next = r_times == O_COUNT ;
  assign O_END = (O_COUNT == I_TIMES) && (r_times == I_TIMES);
  
endmodule

