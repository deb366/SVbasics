//WIP

module VENDIN_MACHINE (
    input clk,
    input reset,
    input [2:0] coin_in, // Encoded to represent different coin denominations
    input [1:0] product_select, // Product selection input
    input refund_request, // Input to request a refund
    output reg [1:0] product_out, // Output the selected product
    output reg [7:0] change_out, // Change to be given back
    output reg dispense, // Signal to dispense product
    output reg refund // Signal to indicate refund
); 
  
    // State declaration
    typedef enum logic [2:0] {
        WAITING = 3'd0,
        COLLECTING_MONEY = 3'd1,
        PRODUCT_SELECT = 3'd2,
        PROVIDE_PRODUCT = 3'd3,
        GIVE_CHANGE = 3'd4,
        REFUND = 3'd5
    } state_t;
  state_t CSTATE,NSTATE;
  
  parameter PRODUCT = 
  
  always_ff @(posedge clk) begin 
    if(!rstn) CSTATE <= WAITING;
    else 	  CSTATE <= NSTATE;
  end 
  
  always_comb begin 
    product_out = '0; change_out = '0; dispense = '0; refund = '0;
    w_balance = coin_in;
    case(CSTATE) 
      WAITING : begin NSTATE = |coin_in ? COLLECTING_MONEY : WAITING; end
      COLLECTING_MONEY : begin NSTATE = |product_select && (w_balance > PRODUCT_A_PRICE) ? PRODUCT_SELECT : COLLECTING_MONEY; end
      PRODUCT_SELECT : begin NSTATE = refund_request ? REFUND : PROVIDE_PRODUCT; w_balance = w_balance - PRODUCT_A_PRICE; end
      PROVIDE_PRODUCT : begin NSTATE = |w_balance? GIVE_CHANGE : WAITING; end
      
      GIVE_CHANGE : begin NSTATE = WAITING; end
      REFUND : begin NSTATE = WAITING; end
  end 
