//This is a parameterised FSM model implemented with One hot encoding 

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

  
  
