
//RED will be high for 40 clk, YELLOW will be high for 10 clk, GREEN will be high for 20 clk  

module TRAFIC_LIGHT(input logic clk,rstn,output logic O_RED,O_YELLOW,O_GREEN);
  
  
  typedef enum logic [1:0] {RED = 2'd0,YELLOW = 2'd1,GREEN = 2'd2} state_t;
  state_t CSTATE,NSTATE;
  
  logic [6:0] r_count;
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      CSTATE <= RED; 
      r_count <= 7'd0;
    end 
    else  begin     
      CSTATE <= NSTATE;
      if (r_count == 7'd69) r_count <= 7'd0;
      else                  r_count <= r_count + 1; 
    end 
  end 
  
  always_comb begin 
    NSTATE = RED;
    case(CSTATE)
      RED    : begin NSTATE = (r_count == 7'd39) ? YELLOW : RED ;end
      YELLOW : begin NSTATE = (r_count == 7'd49) ? GREEN : YELLOW ; end
      GREEN  : begin NSTATE = (r_count == 7'd69) ? RED : GREEN ;end
    endcase
  end 
  
  assign {O_RED,O_YELLOW,O_GREEN} = {(CSTATE == RED),(CSTATE == YELLOW),(CSTATE == GREEN)};
endmodule 
