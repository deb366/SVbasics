// The stabilizer would keep the current temperature(r_cnt) within the two thereshold levels.

module TEMP_STABILIZER(
	input logic clk,rstn,
    input logic [7:0] I_TEMP,
  input logic [7:0] THES_UP,   //set for one time 
  input logic [7:0] THES_DWN,  //set for one time 
  output logic  O_COLLING_ON,
  output logic [7:0] O_TEMP
);

  logic [7:0] r_cnt;
  typedef enum logic [1:0] {IDLE=2'd0,CNT_UP=2'd1,CNT_DWN=2'd2} state_t;
  state_t CSTATE,NSTATE;
  logic w_be_stable;
  
always_ff @(posedge clk) begin 
  if(!rstn) begin 
    CSTATE<= IDLE;
    r_cnt <= '0;
  end 
  else      begin 
    CSTATE<= NSTATE;
    case(CSTATE)
      IDLE : begin r_cnt <= I_TEMP; end   //means this is the current temp
      CNT_UP : begin r_cnt <= r_cnt + 1; end 
      CNT_DWN : begin r_cnt <= r_cnt - 1; end 
    endcase
    
  end 
end 

always_comb begin 
  case(CSTATE)
    IDLE    : begin NSTATE = (r_cnt > THES_UP) ? CNT_DWN : (r_cnt < THES_DWN) ? CNT_UP : IDLE; end
    CNT_UP  : begin NSTATE = w_be_stable ? IDLE : (r_cnt > THES_UP)  ? CNT_DWN : CNT_UP ; end 
    CNT_DWN : begin NSTATE = w_be_stable ? IDLE : (r_cnt < THES_DWN) ? CNT_UP  : CNT_DWN ; end 
  endcase
end
  
  assign O_TEMP = r_cnt;
  assign O_COLLING_ON = r_cnt > THES_UP;
  assign w_be_stable = (r_cnt >= THES_DWN) && (r_cnt <= THES_UP);

endmodule
