//Develop an FSM-based elevator control system in SystemVerilog that manages the movement of an elevator between four floors. Include features for calling the elevator to a floor and //selecting a target floor from inside the elevator.
//Specifications:
//Implement states for moving up, moving down, idle, and emergency stop.
//The elevator should efficiently decide the direction based on current and requested floors.
//Include safety features like door opening only when the elevator is idle at a floor.


//Develop an FSM-based elevator control system in SystemVerilog that manages the movement of an elevator between four floors. Include features for calling the elevator to a floor and //selecting a target floor from inside the elevator.
//Specifications:
//Implement states for moving up, moving down, idle, and emergency stop.
//The elevator should efficiently decide the direction based on current and requested floors.
//Include safety features like door opening only when the elevator is idle at a floor.

// **WIP **//

//Develop an FSM-based elevator control system in SystemVerilog that manages the movement of an elevator between four floors. Include features for calling the elevator to a floor and //selecting a target floor from inside the elevator.
//Specifications:
//Implement states for moving up, moving down, idle, and emergency stop.
//The elevator should efficiently decide the direction based on current and requested floors.
//Include safety features like door opening only when the elevator is idle at a floor.

// **WIP **//
//Develop an FSM-based elevator control system in SystemVerilog that manages the movement of an elevator between four floors. Include features for calling the elevator to a floor and //selecting a target floor from inside the elevator.
//Specifications:
//Implement states for moving up, moving down, idle, and emergency stop.
//The elevator should efficiently decide the direction based on current and requested floors.
//Include safety features like door opening only when the elevator is idle at a floor.


module ELEVATOR (input logic clk,rstn,
                 input logic [3:0] I_DEST_FLOOR,
                 input logic I_EMER_RESOLVE,
                 input logic I_EMERGENCY,
                 output logic [3:0] O_CUR_FLOOR
                );  //consider 10floor building , 0 to 9
  
  typedef enum logic [1:0] {IDLE = 2'd0,MOVING_UP = 2'd1,MOVING_DOWN = 2'd2,EMERGENCY = 2'd3} state_t;
  state_t CSTATE,NSTATE;
  logic [3:0] r_dest_floor,r_current_floor;
  logic w_move_up,w_move_down,w_dst_reached;
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      r_current_floor <= '0;
      r_dest_floor    <= '0;
      CSTATE <= IDLE;
    end 
    else begin 
      case (CSTATE)
        MOVING_UP   : r_current_floor <= w_dst_reached ? r_current_floor : r_current_floor + 1;
        MOVING_DOWN : r_current_floor <= w_dst_reached ? r_current_floor : r_current_floor - 1;
        IDLE        : r_dest_floor    <= w_dst_reached ? I_DEST_FLOOR : r_dest_floor;
        default     : r_current_floor <= r_current_floor; 
      endcase
      CSTATE <= NSTATE;
    end 
  end
  
  always_comb begin 
    case(CSTATE)
      IDLE : NSTATE = I_EMERGENCY ? EMERGENCY : (w_move_up ? MOVING_UP : (w_move_down ? MOVING_DOWN : IDLE));
      MOVING_UP   : NSTATE = I_EMERGENCY ? EMERGENCY : (w_dst_reached ? IDLE : MOVING_UP);
      MOVING_DOWN : NSTATE = I_EMERGENCY ? EMERGENCY : (w_dst_reached ? IDLE : MOVING_DOWN);
      EMERGENCY   : NSTATE = I_EMER_RESOLVE ? IDLE : EMERGENCY;
    endcase
  end 
  
  assign w_move_up = r_dest_floor > r_current_floor;
  assign w_move_down = r_dest_floor < r_current_floor;
  //assign w_dont_move = r_dest_floor == r_current_floor;
  assign w_dst_reached = r_dest_floor == r_current_floor;
  assign O_CUR_FLOOR = r_current_floor;
endmodule 

//++++++++++++++++++++++++++++++++++//
//Test Bench 
//++++++++++++++++++++++++++++++++++//
`timescale 1ns / 1ps

module tb_ELEVATOR;

    // Inputs
    logic clk, rstn;
    logic [3:0] I_DEST_FLOOR;
    logic I_EMER_RESOLVE, I_EMERGENCY;

    // Outputs
    logic [3:0] O_CUR_FLOOR;

    // Instantiate the Elevator Module
    ELEVATOR elevator(
        .clk(clk),
        .rstn(rstn),
        .I_DEST_FLOOR(I_DEST_FLOOR),
        .I_EMER_RESOLVE(I_EMER_RESOLVE),
        .I_EMERGENCY(I_EMERGENCY),
        .O_CUR_FLOOR(O_CUR_FLOOR)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock cycle
    end

    // Test cases
    initial begin
        // Initialize Inputs
        rstn = 0;
        I_DEST_FLOOR = 0;
        I_EMER_RESOLVE = 0;
        I_EMERGENCY = 0;

        // Reset the system
        @(negedge clk);
        rstn = 1;

        // Test moving from floor 0 to floor 3
        @(posedge clk);
        I_DEST_FLOOR = 3;
        
        
        repeat (10) @(posedge clk);
        // Test moving from floor 3 to floor 1
        @(posedge clk);
        I_DEST_FLOOR = 1;
        

        // Trigger emergency while moving
        @(posedge clk);
        I_DEST_FLOOR = 2;
        @(posedge clk);
        I_EMERGENCY = 1;
        
        repeat (10) @(posedge clk);
        // Resolve emergency
        @(posedge clk);
        I_EMER_RESOLVE = 1;
        I_EMERGENCY = 0;
        @(posedge clk);
        I_EMER_RESOLVE = 0;

        // Continue to requested floor
        

        // Complete the simulation
        repeat (8) @(posedge clk);
        @(posedge clk);
        I_DEST_FLOOR = 8;
        
        repeat (3) @(posedge clk);
        @(posedge clk);
        I_DEST_FLOOR = 5;
        repeat (20) @(posedge clk);
        $finish;
    end

    // Display current state and floor
    initial begin
        $monitor("Time=%t, Current State=%s, Current Floor=%d",
                 $time, elevator.CSTATE.name(), O_CUR_FLOOR);
    end
  initial begin 
    $dumpvars();
  end 

endmodule

