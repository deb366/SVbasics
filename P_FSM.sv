//This is a parameterised FSM model implemented with One hot encoding, Here the number of state is known 
// and the number of FSM is parameterised.


module P_FSM #(
    parameter P_NUM_FSM = 8  // Number of states in the FSM
) (
    input logic clk,            // Clock input
    input logic rstn,           // Asynchronous reset (active low)
  input logic [P_NUM_FSM-1:0] I_TRANS_COND,  // Transition conditions
    //output state_t [P_NUM_FSM-1:0] NSTATE        // Next state output
);

  //logic [P_NUM_FSM-1:0] PSTATE;  // Present state register
  typedef enum logic [1:0] {A,B,C,D} state_t;
  state_t [P_NUM_FSM-1:0] PSTATE,NSTATE;

// Sequential logic for state transition on positive edge of clock or negative edge of reset
always_ff @(posedge clk or negedge rstn) begin 
  for(int idx=0;idx<P_NUM_FSM;idx++) begin 
    if (!rstn)
      PSTATE[idx] <= A;  // Reset state to all zeros
    else
      PSTATE[idx] <= NSTATE[idx];  // Transition to next state
	end 
end 

//Here the states are arbitery wo any specific meaning   
  always_comb begin 
    NSTATE = '0;
      for(int idx=0;idx<P_NUM_FSM;idx++) begin 
        case(PSTATE[idx])
          A: begin if (I_TRANS_COND[idx]) NSTATE[idx]= B;
            else NSTATE[idx]= C;
          end 
          B: begin if (I_TRANS_COND[idx]) NSTATE[idx]= D;
            else NSTATE[idx]= C;
          end 
          C: begin if (I_TRANS_COND[idx]) NSTATE[idx]= A;
            else NSTATE[idx]= D;
          end 
          D: begin if (I_TRANS_COND[idx]) NSTATE[idx]= B;
            else NSTATE[idx]= C;
          end                     
        endcase 
      end 
  end 
endmodule

  
/*
module P_FSM #(
    parameter P_NUM_STATE = 8  // Number of states in the FSM
) (
    input logic clk,            // Clock input
    input logic rstn,           // Asynchronous reset (active low)
    input logic [P_NUM_STATE-1:0] I_TRANS_COND,  // Transition conditions
    output logic [P_NUM_STATE-1:0] NSTATE        // Next state output
);

  logic [P_NUM_STATE-1:0] PSTATE;  // Present state register

// Sequential logic for state transition on positive edge of clock or negative edge of reset
always_ff @(posedge clk or negedge rstn) begin 
    if (!rstn)
        PSTATE <= '0;  // Reset state to all zeros
    else
        PSTATE <= NSTATE;  // Transition to next state
end 

// Combinational logic to determine the next state based on current state and transition conditions
always_comb begin 
    NSTATE = '0;  // Default next state is all zeros
    for (int i = 0; i < P_NUM_STATE; i++) begin 
        if (PSTATE[i] && I_TRANS_COND[i]) begin
            // Ensure that we don't exceed the state array bounds
            if (i == P_NUM_STATE - 1)
                NSTATE[0] = 1'b1;  // Wrap to the first state if we've reached the last
            else
                NSTATE[i+1] = 1'b1;  // Move to the next state
        end
    end
end

endmodule
*/
  
  
