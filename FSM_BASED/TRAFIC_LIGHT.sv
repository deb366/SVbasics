
//RED will be high for 40 clk, YELLOW will be high for 10 clk, GREEN will be high for 20 clk  

module TRAFIC_LIGHT(input logic clk,rstn,output logic O_RED,O_YELLOW,O_GREEN);
  
  
  enum typedef logic [1:0] {RED = 2'd0,YELLOW = 2'd1,GREEN = 2'd2} state_t;
  state_t CSTATE,NSTATE;
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      CSTATE <= RED; 
      count <= 7'd0;
    end 
    else  begin     
      CSTATE <= NSTATE;
      if (count == 7'd69) count<= 7'd0;
      else count <= count + 1; 
    end 
  end 
  
  always_comb begin 
    NSTATE = 'h0;
    case(CSTATE)
      RED    : begin NSTATE = (count == 7'd39) ? YELLOW : RED end
      YELLOW : begin NSTATE = (count == 7'd49) ? GREEN : YELLOW end
      GREEN  : begin NSTATE = (count == 7'd69) ? RED : GREEN end
    endcase
  end 
  
  assign {O_RED,O_YELLOW,O_GREEN} = {(CSTATE == RED),(CSTATE == YELLOW),(CSTATE == GREEN)};
endmodule 
