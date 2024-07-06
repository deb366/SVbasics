//The I_STREAM will be compared in progressive manner towards the FINAL state

module DIGITAL_LOCK_SYS(input logic clk,rstn,I_STREAM, output logic O_UNLOCKED);
  
  typedef enum logic [2:0] {IDLE = 3'h0,FIRST = 3'h1,SECOND = 3'h2,THIRD = 3'h3,FINAL = 3'h4} state_t;
  state_t C_STATE,N_STATE;
  
  parameter [3:0] CORRECT_CODE = 4'b1011; //any value can be set
  
  always_ff @(posedge clk)begin 
    if(!rstn)
      C_STATE <= IDLE;
    else 
      C_STATE <= N_STATE;
  end 
  
  always_comb begin 
    O_UNLOCKED = '0;
    case(C_STATE)
      IDLE   : begin N_STATE = (I_STREAM == CORRECT_CODE[3]) ? FIRST : IDLE; O_UNLOCKED = 0; end
      FIRST  : begin N_STATE = (I_STREAM == CORRECT_CODE[2]) ? SECOND : IDLE; O_UNLOCKED = 0; end
      SECOND : begin N_STATE = (I_STREAM == CORRECT_CODE[1]) ? THIRD : IDLE; O_UNLOCKED = 0; end
      THIRD  : begin N_STATE = (I_STREAM == CORRECT_CODE[0]) ? FINAL : IDLE; O_UNLOCKED = 0; end
      FINAL  : begin N_STATE = IDLE ;  O_UNLOCKED = 1; end
    endcase
  end 
endmodule 
