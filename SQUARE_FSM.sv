/*Determine four vertices for a square in x-y plane, create FSM for it.
Breaking the problem: 

Task: Visit the four vertices of a square sequentially, starting at 
(𝑥1,𝑦1)(x1,y1).

States
Each state represents a vertex:

S1: Bottom-left ((𝑥1,𝑦1)(x1​,y1​))
S2: Bottom-right ((𝑥1+𝐿,𝑦1)(x1+L,y1))
S3: Top-right ((𝑥1+𝐿,𝑦1+𝐿)(x1+L,y1+L))
S4: Top-left ((𝑥1,𝑦1+𝐿)(x1,y1+L))
Transitions
Input signal (NEXT) causes the FSM to move to the next vertex.
The FSM loops back to the start after visiting all vertices.
*/

module SQUARE_FSM (
    input logic clk,
    input logic rstn,
    input logic next,
    output logic [1:0] state // Encodes which vertex the FSM is at
);

    typedef enum logic [1:0] {
        S1 = 2'b00, // Vertex 1
        S2 = 2'b01, // Vertex 2
        S3 = 2'b10, // Vertex 3
        S4 = 2'b11  // Vertex 4
    } state_t;

    state_t current_state, next_state;

    // State Transition Logic
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= S1;
        else
            current_state <= next_state;
    end

    // Next State Logic
    always_comb begin
        case (current_state)
            S1: next_state = next ? S2 : S1;
            S2: next_state = next ? S3 : S2;
            S3: next_state = next ? S4 : S3;
            S4: next_state = next ? S1 : S4;
            default: next_state = S1;
        endcase
    end
endmodule
