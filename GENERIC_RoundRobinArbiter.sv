
//Method 1
module RoundRobinArbiter #(parameter NUM_REQUESTORS = 4)
                         (input logic clk,        // Clock
                          input logic rst,        // Reset
                          input logic [NUM_REQUESTORS-1:0] requests,
                          output logic [NUM_REQUESTORS-1:0]  grant);

    // Internal signals
    logic [NUM_REQUESTORS-1:0] grantVector;
  logic [$clog2(NUM_REQUESTORS)-1:0] round;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            grantVector <= '0;
            round <= 0;
        end else begin
            // Rotate the grantVector to the left for the next round
            grantVector <= {grantVector[NUM_REQUESTORS-2:0], grantVector[NUM_REQUESTORS-1]};
            
            // Determine the next round
            round <= (round == NUM_REQUESTORS-1) ? 0 : (round + 1);
            
            // Set the grant signal based on the current round
            grantVector[round] <= requests[round];
        end
    end

 //   assign grant = grantVector[round];
    assign grant = grantVector;


endmodule

//Method 2
module round_robin_arbiter #(
    parameter integer N = 3  // Default number of requesters
)(
    input  logic clk,
    input  logic reset,
    input  logic [N-1:0] request,  // Request inputs for N requesters
    output logic [N-1:0] grant     // Grant outputs for N requesters
);

    // State encoding using a log2 ceiling function for state bits
    localparam integer WIDTH = $clog2(N + 1);
    typedef enum logic [WIDTH-1:0] {
        IDLE = 0,
        REQ = 1  // Start of request states
    } state_t;

    state_t state, next_state;
    logic [WIDTH-1:0] current_req;  // Track the current servicing requester

    // State transition and current request tracking
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE;
            current_req <= 0;
        end else begin
            state <= next_state;
            if (state != IDLE && next_state == IDLE)
                current_req <= (current_req + 1) % N; // Move to the next requester
            else if (state == IDLE && next_state != IDLE)
                current_req <= next_state - REQ; // Update current requester
        end
    end

    // Next state logic based on current state and requests
    always_comb begin
        if (state == IDLE) begin
            // Look for any active requests
            integer i;
            for (i = 0; i < N; i++) begin
                if (request[(current_req + i) % N]) begin
                    next_state = REQ + (current_req + i) % N; // Set next state to the found request
                    break;
                end
            end
            if (i == N)
                next_state = IDLE; // No active requests found
        end else begin
            if (request[current_req])
                next_state = state; // Continue servicing current request
            else
                next_state = IDLE; // No further request, go to IDLE
        end
    end

    // Grant logic based on state
    always_comb begin
        grant = {N{1'b0}}; // Default to no grants
        if (state != IDLE && state >= REQ)
            grant[state - REQ] = 1'b1; // Grant to current requester
    end

endmodule

