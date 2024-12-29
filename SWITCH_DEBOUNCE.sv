/* Switch debounce rtl logic for proper switching detection and debounce duration of 10ns
Problem breakdown: The design basically needs the output to take the input(stayed constant for DEBOUNCE_PERIOD). The output willl not take the input value if the input changes before the DEBOUNCE_PERIOD.  
*/

module SWITCH_DEBOUNCE #(
    parameter DEBOUNCE_PERIOD = 10,  // 10ns debounce period
    parameter CLOCK_FREQ = 100000000 // Assuming 100MHz clock
)(
    input wire clk,          // System clock
    input wire rst_n,        // Active low reset
    input wire switch_in,    // Raw input from mechanical switch
    output reg switch_out    // Debounced switch output
);

    // Calculate counter width based on clock frequency and debounce period
    // Counter_width = ceil(log2(CLOCK_FREQ * DEBOUNCE_PERIOD / 1e9))
    localparam COUNTER_WIDTH = 4;  // For 10ns at 100MHz we need very few bits
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam CHECK_BOUNCE = 2'b01;
    localparam WAIT_STABLE = 2'b10;
    
    // Internal registers
    reg [1:0] current_state, next_state;
    reg [COUNTER_WIDTH-1:0] counter;
    reg switch_sync1, switch_sync2; // Double flopping for metastability
    wire switch_sync;
    
    // Double flop synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_sync1 <= 1'b0;
            switch_sync2 <= 1'b0;
        end else begin
            switch_sync1 <= switch_in;
            switch_sync2 <= switch_sync1;
        end
    end
    
    assign switch_sync = switch_sync2;
    
    // State and counter registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            counter <= 0;
        end else begin
            current_state <= next_state;
            if (current_state == CHECK_BOUNCE) begin
                counter <= counter + 1;
            end else begin
                counter <= 0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (switch_sync != switch_out)
                    next_state = CHECK_BOUNCE;
            end
            
            CHECK_BOUNCE: begin
                if (switch_sync != switch_out) begin
                    if (counter == (DEBOUNCE_PERIOD-1))
                        next_state = WAIT_STABLE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            WAIT_STABLE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_out <= 1'b0;
        end else if (current_state == WAIT_STABLE) begin
            switch_out <= switch_sync;
        end
    end

endmodule
