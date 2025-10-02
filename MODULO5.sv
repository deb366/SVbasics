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
// Parameterised Code 

module modulo_calculator #(
    parameter int N = 3,           // Modulo value (natural number)
    parameter int WIDTH = $clog2(N) // Width needed for remainder
) (
    input  logic clk,
    input  logic reset,
    input  logic bit_in,           // Incoming bit (MSB first)
    input  logic bit_valid,        // Valid signal for the input bit
    output logic [WIDTH-1:0] remainder,  // Current remainder modulo N
    output logic remainder_valid   // Valid signal for remainder output
);

    // Input validation
    initial begin
        if (N < 1) begin
            $error("N must be a natural number (N >= 1)");
        end
    end

    // FSM states
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        PROCESSING = 2'b01,
        VALID_OUTPUT = 2'b10
    } state_t;
    
    state_t current_state, next_state;
    logic [WIDTH-1:0] current_remainder, next_remainder;
    logic output_valid_reg;
    logic [WIDTH:0] temp_result;   // Extra bit for intermediate calculation

    // State transition and remainder calculation
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            current_remainder <= '0;
            output_valid_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            current_remainder <= next_remainder;
            output_valid_reg <= (next_state == VALID_OUTPUT);
        end
    end

    // Next state logic and remainder calculation
    always_comb begin
        next_state = current_state;
        next_remainder = current_remainder;
        temp_result = '0;
        
        case (current_state)
            IDLE: begin
                if (bit_valid) begin
                    next_state = PROCESSING;
                    // For first bit: remainder = bit_value % N
                    next_remainder = (bit_in ? 1 : 0) % N;
                end
            end
            
            PROCESSING: begin
                if (bit_valid) begin
                    // For accumulated number: new_remainder = (current_remainder * 2 + bit_in) % N
                    temp_result = (current_remainder << 1) + (bit_in ? 1 : 0);
                    if (temp_result >= N) begin
                        next_remainder = temp_result - N;
                    end else begin
                        next_remainder = temp_result[WIDTH-1:0];
                    end
                    next_state = VALID_OUTPUT;
                end else begin
                    next_state = PROCESSING;
                end
            end
            
            VALID_OUTPUT: begin
                next_state = bit_valid ? PROCESSING : VALID_OUTPUT;
                if (bit_valid) begin
                    // Continue processing with new bit
                    temp_result = (current_remainder << 1) + (bit_in ? 1 : 0);
                    if (temp_result >= N) begin
                        next_remainder = temp_result - N;
                    end else begin
                        next_remainder = temp_result[WIDTH-1:0];
                    end
                end
            end
        endcase
    end

    // Output assignments
    assign remainder = current_remainder;
    assign remainder_valid = output_valid_reg;

endmodule

//------- Method 3 --------//
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
