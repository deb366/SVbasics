// 45.	Design a logic to clock out index of bits having 1 value on a 8bit number and use minimal number clocks. [example 1000 1100 will give 2,3,7 at 3 consecutive clocks] 
//WIP


module COUNT_TIMES #(parameter N =4) (input logic clk,rstn, output logic [$clog2(N)-1:0] O_COUNT);
  
  localparam N0 = $clog2(N);  // Number of bits to count up to N
  logic [N0-1:0] r_times;
  logic r_times, w_next;

always_ff @(posedge clk)begin 
  if(!rstn) O_COUNT <= 'h0;
  else begin 
    if(w_next) begin 
    	O_COUNT <= O_COUNT + 1;
      	r_times < = 'h0;
    end 
    else begin 
      O_COUNT <= O_COUNT;
      r_times <= r_times + 1;
    end 
  end 
end 

assign w_next = r_times == O_COUNT;
  
endmodule
