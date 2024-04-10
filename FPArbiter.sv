//This is Fixed Priority Arbiter

module top_module (
    input clk,
    input resetn,    // active-low synchronous reset
    input [3:1] r,   // request
    output [3:1] g   // grant
); 
    enum logic [1:0] {A,B,C,D} pstate,nstate;
    always_ff @(posedge clk) begin 
        if(!resetn)   pstate<=A;
        else              pstate<=nstate;
    end 
    always_comb begin 
        g[3:1] = 3'b0;
        case(pstate)  
            A: begin nstate= r[1] ? B : (r[2]? C : (r[3]? D : A)) ; g[3:1] = 3'b0;  end
            B: begin nstate= r[1] ? B : A; g[1] = 1'b1;  end
            C: begin nstate= r[2] ? C : A; g[2] = 1'b1;  end
            D: begin nstate= r[3] ? D : A; g[3] = 1'b1;  end
        
        endcase
    end 
endmodule


//Alternative code 
Lsb has highest priority, no request no grant 

//Code
module fixed_priority  #(parameter N = 4)
  (//number of requester 
    input logic [N-1:0] req,
    output logic [N-1:0] grant
  );
  assign grant[0]=req[0];
  
  always_comb begin : arbitration
    for(int i=1;i<N;i++)
      grant[i] = req[i] & !(|req[i-1:0]);
  end: arbitration
  
endmodule

