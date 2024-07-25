//2 input BYTE is merged to form the 2BYTE output , it can be extended to 2 BYTE merger just by limiting the max count value 

module BYTE_MERGER(
  input logic clk,rstn,
  input logic [7:0] I_DATA,
  input logic I_VALID,
  output logic O_VALID,
  output logic [15:0] O_DATA,
);
  
  logic r_cnt,r_valid;
  logic [15:0] r_merged;
  
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      r_cnt <= '0;
      r_merged <= '0;
      r_valid <= 0;
    end 
    else if(I_VALID) begin 
      r_merged<={r_merged[7:0],I_DATA};
      r_cnt <= r_cnt + 1;   
      r_valid <=I_VALID;
    end 
    else 
      r_valid <= 0;
  end 
  
  assign O_DATA = r_merged;
  assign O_VALID = !(&r_cnt) && r_valid;
  
endmodule
