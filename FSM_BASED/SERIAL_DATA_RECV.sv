/* Design a SystemVerilog module for an FSM-based serial data receiver that processes incoming data packets framed by start and stop //bits. The FSM should verify the correctness of the packet format and handle errors.

Specifications:

Support a simple packet structure: start bit, 8 data bits, parity bit, stop bit.
Validate the parity and frame correctness.
On detecting errors, the FSM should signal an error state and discard the packet.

*/
// WIP //

module SERIAL_DATA_RECV(input logic clk,rstn,I_SERIAL_DATA,output logic O_ERROR);
  
  //total clk count will be 11 (1 bit start, 8 bit data, 1 bit parity, 1 bit stop, )
  
  logic [3:0] r_count;
  logic w_error,r_parity;
  
  typedef enum logic [2:0] {IDLE = 3'd0,DATA_CHECK = 3'd1,PARITY_CHECK = 3'd2,CORRECT = 3'd3,ERROR = 3'd4} state_t;
  state_t CSTATE,NSTATE;
  always_ff @(posedge clk) begin 
    if(!rstn) begin 
      CSTATE <= IDLE;
      r_count <= '0;
      r_parity <= 0;
    end
    else begin 
      CSTATE <= NSTATE;
      case(CSTATE)
        DATA_CHECK: begin 
          r_count <= r_count + 1;
          r_parity <= ((r_count>4'd0) && (r_count<4'd9)) ? (r_parity ^ I_SERIAL_DATA) : r_parity;
        end 
        PARITY_CHECK: r_count <= r_count + 1;
        IDLE: begin r_count= '0; r_parity = '0; end 
        default: r_count <= r_count;
      endcase
    end 
    
  end 
  always_comb begin 
    O_ERROR = 0;
    case(CSTATE)
      IDLE: begin NSTATE = (I_SERIAL_DATA && (~|r_count)) ? DATA_CHECK : IDLE; end
      DATA_CHECK: begin 
        NSTATE = (r_count== 4'd8) ? PARITY_CHECK : DATA_CHECK;
        w_error = (I_SERIAL_DATA != r_parity) && (r_count == 4'd9);
      end 
      PARITY_CHECK: begin NSTATE = w_error ? ERROR : CORRECT ; end 
      CORRECT: begin NSTATE = IDLE; O_ERROR = 0 ; end 
      ERROR:   begin NSTATE = IDLE; O_ERROR = 1 ; end
    endcase
  end 
  
endmodule 
