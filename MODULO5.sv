//Same incoming input stream but the data is accumulated at the MSB,  (i.e   100,1100,01100,  001100, 1001100) , write a code to 
//find the //modulo of the whole number by 5 (accumulated vector % 5)

// Method 1 //

module div_by_3_checker (
    input  logic clk,
    input  logic reset,
    input  logic bit_in,
    output logic divisible
);
    logic state_parity;       // 0: even, 1: odd
    logic [1:0] state_remainder; // Remainder modulo 3 (0, 1, 2)
    logic [2:0] temp;         // Temporary storage for next remainder calculation

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state_parity <= 1'b0;
            state_remainder <= 2'b0;
        end else begin
            state_parity <= ~state_parity; // Toggle parity each cycle
            // Compute next remainder based on current parity and input bit
            if (state_parity == 1'b0) begin
                temp = bit_in + state_remainder;
            end else begin
                temp = 2 * bit_in + state_remainder;
            end
            // Adjust if temp exceeds 2 (modulo 3 operation)
            if (temp >= 3) begin
                state_remainder <= temp - 3;
            end else begin
                state_remainder <= temp[1:0];
            end
        end
    end

    assign divisible = (state_remainder == 2'b0);
endmodule

//---- Method 2 -----------//
// Code 
module mod5(
  input logic I_STREAM,
  input logic clk,rstn,
  output logic [2:0] O_MOD5
);
  
  logic [2:0] r_mod5;
  logic [4:0] w_incr;
  typedef enum logic [2:0] {S0,S1,S2,S3} state;
  state cstate,nstate;
  
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      cstate <= S0;
    end
    else begin 
      cstate <=nstate;
      r_mod5<= (r_mod5+ w_incr) % 5 ;
    end 
  end 
  
  always_comb begin 
    case(cstate)
      S0: begin  nstate = S1 ; w_incr = I_STREAM; end
      S1: begin  nstate = S2 ; w_incr = I_STREAM ? 2 : 0 ; end 
      S2: begin  nstate = S3 ; w_incr = I_STREAM ? 4 : 0 ; end 
      S3: begin  nstate = S0 ; w_incr = I_STREAM ? 3 : 0 ; end 
    endcase
  end 
      
      assign O_MOD5 = r_mod5;
  
endmodule 
