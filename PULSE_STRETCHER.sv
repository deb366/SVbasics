//The output pulse willbe stretched by the number inidcated I_NO_PULSE. I_NO_PULSE must be non zero value and the I_VALID 
//is pulse to indicate the valid value of I_NO_PULSE  

module PULSE_STRETCHER #(parameter N = 4) 
  (input clk,rstn,I_VALID,
   input [N-1:0] I_NO_STRETCH, //min value = 1
  output O_PULSE);
  
  logic [N-1:0] r_count;
  logic r_done;
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      r_count <= '0;
      r_done  <= 1'b0;
      
    end
    else begin 
      if (r_count == (I_NO_STRETCH))begin 
        r_count <= '0;
        r_done  <= 1'b1;
      end 
      else if((I_VALID && !(|r_count)) || !r_done) begin 
        r_count <= r_count + 1'b1;
        r_done  <= 1'b0;
      end 
    end 
  end 
  
  assign O_PULSE = |r_count;
  
endmodule 
