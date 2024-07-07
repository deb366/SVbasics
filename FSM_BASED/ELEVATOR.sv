//Develop an FSM-based elevator control system in SystemVerilog that manages the movement of an elevator between four floors. Include features for calling the elevator to a floor and //selecting a target floor from inside the elevator.
//Specifications:
//Implement states for moving up, moving down, idle, and emergency stop.
//The elevator should efficiently decide the direction based on current and requested floors.
//Include safety features like door opening only when the elevator is idle at a floor.

// **WIP **//
module ELEVATOR (input logic clk,rstn,
                 input logic [3:0] I_DEST_FLOOR,
                 input logic I_EMER_RESOLVE,
                 output logic [3:0] O_CUR_FLOOR
                );  //consider 10floor building , 0 to 9
  
  typedef enum logic [1:0] {IDLE = 2'd0,MOVING_UP = 2'd1,MOVING_DOWN = 2'd2,EMERGENCY = 2'd3} state_t;
  state_t CSTATE,NSTATE;
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      r_current_floor <= '0;
      r_dst_floor     <= '0;
      CSTATE <= IDLE;
    end 
    else begin 
      case (CSTATE)
        MOVING_UP   : r_current_floor <= r_current_floor + 1;
        MOVING_DOWN : r_current_floor <= r_current_floor - 1;
        default     : r_current_floor <= r_current_floor; 
      endcase
      CSTATE <= NSTATE;
    end 
  always_comb begin 
    case(CSTATE)
      IDLE : NSTATE = w_dont_move ? IDLE : emmergency_stop ? EMERGENCY : (w_move_up ? MOVING_UP : (w_move_down ? MOVING_DOWN : IDLE));
      MOVING_UP   : NSTATE = w_dont_move ? IDLE : emmergency_stop ? EMERGENCY : (w_move_down ? MOVING_DOWN : MOVING_UP));
      MOVING_DOWN : NSTATE = w_dont_move ? IDLE : emmergency_stop ? EMERGENCY : (w_move_up ? MOVING_UP : MOVING_DOWN));
      EMERGENCY   : NSTATE = I_EMER_RESOLVE ? IDLE : EMERGENCY;
    endcase
  end 
  
  assign w_move_up = I_DEST_FLOOR > r_current_floor;
  assign w_move_down = I_DEST_FLOOR < r_current_floor;
  assign w_dont_move = I_DEST_FLOOR == r_current_floor;
  assign w_dst_reached = r_dst_floor == r_current_floor;
endmodule 
