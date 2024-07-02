
//Design a logic to clock out index of bits having 1 value on a 8bit number and use minimal number clocks. [example 1000 1100 will give 2,3,7 at 3 consecutive clocks] 

module INDEX_COUNT #(parameter N = 8) (input logic clk,rstn, input logic I_LOAD, input logic [N-1:0] I_VECTOR, output logic [$clog2(N)-1:0] O_INDEX);
//the I_LOAD is a pulse, indicating the new input arrival 
  localparam N0 = $clog2(N);
  logic [N0-1:0] w_index;  
  logic [N-1:0] r_temp;


always_comb begin
  w_index = 'h0;
  for (int i=0;i<N;i++)begin 
    if(r_temp[i]) begin //try to detect 1st 1 from LSB at each clock
      w_index = i[2:0]; 
      break;
    end 
  end 
end

always_ff @(posedge clk) begin 
  if(!rstn) begin 
    r_temp <= 'h0;
  end 
  else if (I_LOAD) begin 
  	r_temp <= I_VECTOR;  
  end 
  else begin 
    r_temp[w_index] = 1'b0; //after detecting 1, fill that index with 0
  end 
end 

assign O_INDEX = w_index;
  
endmodule 
