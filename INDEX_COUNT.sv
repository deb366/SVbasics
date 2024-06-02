//Design a logic to clock out index of bits having 1 value on a 8bit number and use minimal number clocks. [example 1000 1100 will give 2,3,7 at 3 consecutive clocks] 

module INDEX_COUNT #(parameter N) (input logic clk,rstn, output logic [$clog2(N)-1:0] O_INDEX);

  localparam N0 = $clog2(N);
  logic [N0-1:0] w_index  


always_comb begin
  w_index = 'h0;
  for (int i=0;i<8;i++)begin 
    if(r_temp[i]) begin 
      w_index = i[2:0];
      break;
    end 
  end 
end

always_ff @(posedge clk) begin 
  if(!rstn) begin 
    r_temp <= I_VECTOR;
  end 
  else begin 
    r_temp[w_index] = 1'b0;
  end 
end 

assign O_INDEX = w_index;
  
endmodule 
