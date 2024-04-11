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
