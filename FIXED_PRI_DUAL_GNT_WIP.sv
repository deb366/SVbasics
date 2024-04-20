//This module will grant two requester at a time, It takes 4 requester and grant 2 of them.


module fixed_priority_arbiter_dual_grant_fsm(
    input logic clk,
    input logic rst_n,
    input logic [3:0] req,     // Request inputs from 4 requesters
    output logic [3:0] grant    // Grant outputs for up to 2 of 4 requesters simultaneously
);

    // Define the FSM states
    typedef enum logic [3:0] {
        IDLE = 4'b0000,       // No grants
        GRANT_0 = 4'b0001,    // Granted to requester 0
        GRANT_1 = 4'b0010,    // Granted to requester 1
        GRANT_2 = 4'b0100,    // Granted to requester 2
        GRANT_3 = 4'b1000,    // Granted to requester 3
        GRANT_0_1 = 4'b0011,  // Granted to requesters 0 and 1
        GRANT_0_2 = 4'b0101,  // Granted to requesters 0 and 2
        GRANT_0_3 = 4'b1001,  // Granted to requesters 0 and 3
        GRANT_1_2 = 4'b0110,  // Granted to requesters 1 and 2
        GRANT_1_3 = 4'b1010,  // Granted to requesters 1 and 3
        GRANT_2_3 = 4'b1100   // Granted to requesters 2 and 3
    } state_t;

    state_t current_state, next_state;

    // State transition and output logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic based on current state and requests
    always_comb begin
        next_state = current_state; // Default to stay in the current state
        grant = 4'b0000;           // Default to no grants

        case (current_state)
            IDLE: begin
                // Prioritize requests in order from 0 to 3
                if (req[0]) next_state = GRANT_0;
                else if (req[1]) next_state = GRANT_1;
                else if (req[2]) next_state = GRANT_2;
                else if (req[3]) next_state = GRANT_3;
            end
            GRANT_0: begin
                grant = 4'b0001;
                if (req[1]) next_state = GRANT_0_1;
                else if (req[2]) next_state = GRANT_0_2;
                else if (req[3]) next_state = GRANT_0_3;
                else if (~req[0]) next_state = IDLE;  // Release grant if request is no longer active
            end
            
            GRANT_1: begin
                grant = 4'b0010;
                if (req[0]) next_state = GRANT_0_1;
                else if (req[2]) next_state = GRANT_1_2;
                else if (req[3]) next_state = GRANT_1_3;
                else if (~req[1]) next_state = IDLE;
            end
            GRANT_2: begin
                grant = 4'b0100;
                if (req[0]) next_state = GRANT_0_2;
                else if (req[1]) next_state = GRANT_1_2;
                else if (req[3]) next_state = GRANT_2_3;
                else if (~req[2]) next_state = IDLE;
            end
            GRANT_3: begin
                grant = 4'b1000;
                if (req[0]) next_state = GRANT_0_3;
                else if (req[1]) next_state = GRANT_1_3;
                else if (req[2]) next_state = GRANT_2_3;
                else if (~req[3]) next_state = IDLE;
            end
            GRANT_0_1: begin
                grant = 4'b0011;
                // Release either grant if the corresponding request is no longer active
                if (~req[0]) next_state = GRANT_1;
                else if (~req[1]) next_state = GRANT_0;
                // Transition to IDLE if both requests are no longer active
                else if (~req[0] && ~req[1]) next_state = IDLE;
            end
            GRANT_0_2: begin
                grant = 4'b0101;
                // Release either grant if the corresponding request is no longer active
              	if (~req[0]) next_state = GRANT_2;
              	else if (~req[2]) next_state = GRANT_0;
                // Transition to IDLE if both requests are no longer active
              	else if (~req[0] && ~req[2]) next_state = IDLE;
            end          
          
            
            GRANT_0_3: begin
                grant = 4'b1001;
                if (~req[0]) next_state = GRANT_3;
                else if (~req[3]) next_state = GRANT_0;
                else if (~req[0] && ~req[3]) next_state = IDLE;
            end
            
            GRANT_1_2: begin
                grant = 4'b0110;
                // Release either grant if the corresponding request is no longer active
              	if (~req[1]) next_state = GRANT_2;
              	else if (~req[2]) next_state = GRANT_1;
                // Transition to IDLE if both requests are no longer active
              	else if (~req[1] && ~req[2]) next_state = IDLE;
            end          
            GRANT_1_3: begin
                grant = 4'b1010;
                if (~req[1]) next_state = GRANT_3;
                else if (~req[3]) next_state = GRANT_1;
                else if (~req[1] && ~req[3]) next_state = IDLE;
            end
            GRANT_2_3: begin
                grant = 4'b1100;
                if (~req[2]) next_state = GRANT_3;
                else if (~req[3]) next_state = GRANT_2;
                else if (~req[2] && ~req[3]) next_state = IDLE;
            end
            default: next_state = IDLE;  // Handle undefined states
        endcase
    end

endmodule
