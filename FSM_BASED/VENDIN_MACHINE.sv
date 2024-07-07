//Create a SystemVerilog module for a vending machine that accepts coins, selects products, and provides change. Use an FSM to handle various states such as waiting, collecting money, //product selection, and change dispensing.

//Specifications:
//Support at least three different products with different prices.
//Handle exact and excess money scenarios.
//Provide a refund mechanism that can be triggered at any money-collecting state.

//** WIP **//
module VendingMachine(
    input logic clk,
    input logic rstn,
    input logic [3:0] coin_inserted,
    input logic [1:0] select_product,
    input logic trigger_refund,
    output logic [1:0] product_out,
    output logic [7:0] change_given,
    output logic [7:0] refund_given,
    output logic O_DONE
);

    typedef enum logic [2:0] {
        IDLE,
        COLLECT_MONEY,
        PRODUCT_SELECT,
        CHECK_MONEY,
        DISPENSE_PRODUCT,
        DISPENSE_CHANGE,
        REFUND
    } state_t;

    state_t current_state, next_state;

    logic [7:0] total_inserted;
    logic [7:0] price;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            current_state <= IDLE;
            //total_inserted <= 0;
            //price <= 0;  // Reset the price
            //product_out <= 0;
            //change_given <= 0;
            //refund_given <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        O_DONE = 0;
        case (current_state)
            IDLE: begin
                if (coin_inserted > 0) next_state = COLLECT_MONEY;
                O_DONE = 0;
            end
            COLLECT_MONEY: begin
                if (trigger_refund) next_state = REFUND;
                else //if (coin_inserted > 0) total_inserted <= total_inserted + coin_inserted;
                     next_state = PRODUCT_SELECT;
            end
            PRODUCT_SELECT: begin
                if (select_product != 0) next_state = CHECK_MONEY; // Move to check money if product is selected
            end
            CHECK_MONEY: begin
                if (total_inserted >= price) next_state = DISPENSE_PRODUCT;
                else next_state = COLLECT_MONEY;
            end
            DISPENSE_PRODUCT: begin
                if (total_inserted > price) next_state = DISPENSE_CHANGE;
                else next_state = IDLE;
            end
            DISPENSE_CHANGE: begin
                next_state = IDLE;
                O_DONE = 1;
            end
            REFUND: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk) begin
      if(!rstn) begin 
            total_inserted <= 0;
            price <= 0;  // Reset the price
            product_out <= 0;
            change_given <= 0;
            refund_given <= 0;
      end 
      else begin 
        case (current_state)
            COLLECT_MONEY: begin
                // Accumulate coins only when they are inserted
                if (coin_inserted > 0) total_inserted <= total_inserted + coin_inserted;
            end
            PRODUCT_SELECT: begin
                // Determine the price based on the selected product
                case (select_product)
                    2'b01: price <= 10;
                    2'b10: price <= 15;
                    2'b11: price <= 20;
                    default: price <= 0;
                endcase
            end
            DISPENSE_PRODUCT: begin
                product_out <= select_product;
            end
            DISPENSE_CHANGE: begin
                change_given <= total_inserted - price;
                total_inserted <= 0;  // Reset total_inserted after dispensing change
                price <= 0;  // Reset the price after dispensing change
            end
            REFUND: begin
                refund_given <= total_inserted;
                total_inserted <= 0;  // Reset total_inserted after refund
                price <= 0;  // Reset the price after refund
            end
            default: begin
              //  total_inserted <= 0;
            //    product_out <= 0;
                //change_given <= 0;
                //refund_given <= 0;
                //price <= 0;  // Ensure price is reset in all other conditions
            end
        endcase
      end
    end 

endmodule
