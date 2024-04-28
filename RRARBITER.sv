`timescale 1ns / 1ps
module roundrobin_arbiter(
input clk,rst_n,
input [3:0] REQ,
output reg [3:0] GNT
    );
    reg[2:0] pr_state;
    reg[2:0] nxt_state;
    
   // parameter [2:0] Sideal = 3'b000;
   // parameter [2:0]     S0 = 3'b001;
   // parameter [2:0]     S1 = 3'b010;
   // parameter [2:0]     S2 = 3'b011;
   // parameter [2:0]     S3 = 3'b100;
    
enum logic [2:0] {Sideal,S0,S1,S2,S3};
    always @(posedge clk or negedge rst_n)
    
    begin
    if(!rst_n)
     pr_state <= Sideal;
     else 
      pr_state <=nxt_state;
     end
      
    always@(*)
    begin   
          case(pr_state) 
            Sideal:
                     begin 
                         if(REQ[0])
                             nxt_state = S0;
                         else if (REQ[1])
                              nxt_state = S1;
                         else if (REQ[2])
                            nxt_state = S2;
                         else if (REQ[3])
                            nxt_state = S3;
                          else 
                             nxt_state =Sideal;
                     end 
               S0: 
                     begin   
                         if (REQ[1])
                            nxt_state = S1;
                         else if (REQ[2])
                            nxt_state = S2;
                         else if (REQ[3])
                              nxt_state = S3;
                         else if(REQ[0])
                             nxt_state =S0;
                         else 
                             nxt_state =Sideal;
                     end 
            
               S1: 
                     begin   
                          if (REQ[2])
                            nxt_state = S2;
                         else if (REQ[3])
                              nxt_state = S3;
                         else if(REQ[0])
                             nxt_state =S0;
                           else if (REQ[1])
                            nxt_state = S1;
                            else 
                             nxt_state =Sideal;
                     end 
               S2: 
                     begin   
                        if (REQ[3])
                              nxt_state = S3;
                         else if(REQ[0])
                             nxt_state =S0;
                           else if (REQ[1])
                            nxt_state = S1;
                            else if (REQ[2])
                            nxt_state = S2;
                            else 
                             nxt_state =Sideal;
                     end 
                 S3: 
                     begin   
                            if(REQ[0])
                             nxt_state =S0;
                           else if (REQ[1])
                            nxt_state = S1;
                            else if (REQ[2])
                            nxt_state = S2;
                            else if (REQ[3])
                              nxt_state = S3;
                            else 
                             nxt_state =Sideal;
                     end 
                    default: 
                     begin 
                         if(REQ[0])
                             nxt_state = S0;
                         else if (REQ[1])
                              nxt_state = S1;
                         else if (REQ[2])
                            nxt_state = S2;
                         else if (REQ[3])
                            nxt_state = S3;
                          else 
                             nxt_state =Sideal;
                    end
       endcase         
         
 end              
    always @(*)
     begin
        case (pr_state)
        S0: GNT=4'b0001;
        S1: GNT=4'b0010;
        S2: GNT=4'b0100;
        S3: GNT=4'b1000;
        default: GNT=4'b0000;
        endcase
     end   
endmodule

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
// The below code allows the requester 0 with highest priority 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//

module round_robin_arbiter(
    input logic clk,
    input logic reset,
    input logic [3:0] request,  // Request inputs from 4 requesters
    output logic [3:0] grant    // Grant outputs to 4 requesters
);

    // State encoding for each requester
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        REQ0 = 3'b001,
        REQ1 = 3'b010,
        REQ2 = 3'b011,
        REQ3 = 3'b100  // Added state for the fourth requester
    } state_t;

    state_t state, next_state;

    // State transition logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic based on current state and requests
    always_comb begin
        case (state)
            IDLE: begin
                if (request[0])
                    next_state = REQ0;
                else if (request[1])
                    next_state = REQ1;
                else if (request[2])
                    next_state = REQ2;
                else if (request[3])
                    next_state = REQ3; // Handling request from the fourth requester
                else
                    next_state = IDLE;
            end
            REQ0: begin
                if (request[0])
                    next_state = REQ0;              
                else if (request[1])
                    next_state = REQ1;
                else if (request[2])
                    next_state = REQ2;
                else if (request[3])
                    next_state = REQ3;
                else
                    next_state = IDLE;
            end
            REQ1: begin
                if (request[0])
                    next_state = REQ0;               
                else if (request[2])
                    next_state = REQ2;
                else if (request[3])
                    next_state = REQ3;
                else if (request[1])
                    next_state = REQ1;
                else
                    next_state = IDLE;
            end
            REQ2: begin
                if (request[0])
                    next_state = REQ0;               
                else if (request[3])
                    next_state = REQ3;
                else if (request[1])
                    next_state = REQ1;
                else if (request[2])
                    next_state = REQ2;
                else
                    next_state = IDLE;
            end
            REQ3: begin
                if (request[0])
                    next_state = REQ0;
                else if (request[1])
                    next_state = REQ1;
                else if (request[2])
                    next_state = REQ2;
                else if (request[3])
                    next_state = REQ3;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Grant logic based on state
    always_comb begin
        grant = 4'b0000; // Default to no grants, updated to handle 4 requesters
        case (state)
            REQ0: grant[0] = 1;
            REQ1: grant[1] = 1;
            REQ2: grant[2] = 1;
            REQ3: grant[3] = 1; // Added grant for the fourth requester
            default: grant = 4'b0000;
        endcase
    end

endmodule

