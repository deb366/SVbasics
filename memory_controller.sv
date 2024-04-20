// Design a parameterized memory controller module that interfaces with external memory devices (e.g., DDR SDRAM) and supports read, write, and refresh operations. 
//The controller should handle address mapping, data buffering, and timing constraints.

module memory_controller #(
    parameter ADDR_WIDTH = 28,  // Width of the address bus for memory
    parameter DATA_WIDTH = 64,  // Width of the data bus for memory
    parameter REFRESH_INTERVAL = 7800  // DDR SDRAM refresh interval in clock cycles
) (
    input logic clk, 
    input logic rst_n, 
    input logic [ADDR_WIDTH-1:0] addr, 
    input logic [DATA_WIDTH-1:0] write_data, 
    input logic read_en, 
    input logic write_en,
  	input logic pause_refresh,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic ready,
    // DDR memory interface signals
    output logic [ADDR_WIDTH-1:0] ddr_addr, 
    output logic [DATA_WIDTH-1:0] ddr_data_in, 
    input logic [DATA_WIDTH-1:0] ddr_data_out,
    output logic ddr_read_en,
    output logic ddr_write_en,
    output logic ddr_refresh
);

// State definition for the memory controller
typedef enum logic [2:0] {
    IDLE,
    READ,
    WRITE,
    REFRESH,
    WAIT,
    REFRESH_PAUSE  // State where refresh is temporarily paused
} mem_state_t;

mem_state_t current_state, next_state;

// Internal registers for buffering and state machine control
logic [DATA_WIDTH-1:0] buffer;
logic [ADDR_WIDTH-1:0] current_addr;
logic refresh_timer_en;
integer refresh_timer;

// Sequential logic for state transitions and refresh timer
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        //current_addr <= '0;
        //buffer <= '0;
        refresh_timer <= 0;
        refresh_timer_en <= 1'b1;  // Enable refresh timer by default
    end else begin
        current_state <= next_state;

        // Refresh timer control logic
        if (current_state != REFRESH_PAUSE) begin
            refresh_timer_en <= 1'b1; // Enable the timer except when paused
            refresh_timer <= (refresh_timer >= REFRESH_INTERVAL) ? 0 : refresh_timer + 1;
        end else begin
            refresh_timer_en <= 1'b0; // Disable the timer in REFRESH_PAUSE state
        end
    end
end

// Combinational logic for determining the next state
always_comb begin
    next_state = current_state; // Default is to stay in the current state
    ready = 1'b0;
    ddr_read_en = 1'b0;
    ddr_write_en = 1'b0;
    ddr_refresh = 1'b0;
    ddr_addr = current_addr;
    ddr_data_in = buffer;
  	buffer = 0;
    
    case (current_state)
        IDLE: begin
            if (read_en) begin
                next_state = READ;
                current_addr = addr;
            end else if (write_en) begin
                next_state = WRITE;
                buffer = write_data;
                current_addr = addr;
            end else if (refresh_timer >= REFRESH_INTERVAL) begin
                next_state = REFRESH;
            end
        end
        READ: begin
            ddr_read_en = 1'b1;
            ready = 1'b1;
            read_data = ddr_data_out; // Data read from DDR memory
            next_state = WAIT; // Transition to WAIT state for read completion
        end
        WRITE: begin
            ddr_write_en = 1'b1;
            ready = 1'b1;
            next_state = WAIT; // Transition to WAIT state for write completion
        end
        REFRESH: begin
            ddr_refresh = 1'b1;
            next_state = WAIT; // Transition to WAIT state for refresh completion
        end
        WAIT: begin
            // Logic to handle waiting period based on memory operation latency
            // This will be dependent on the DDR memory specifications
            // For simplicity, let's transition to IDLE after a fixed delay
            next_state = IDLE; // Transition to IDLE state assuming completion of the DDR operation
        end
        REFRESH_PAUSE: begin
          //**
           //REFRESH_PAUSE: begin
            if (!pause_refresh) begin
                // If pause signal is deasserted, resume normal operation
                next_state = IDLE;
            end else if (refresh_timer >= REFRESH_INTERVAL) begin
                // Even if we are pausing, we must ensure the refresh happens
                // periodically to prevent data loss. So if the refresh timer has expired,
                // perform the refresh despite the pause request.
                next_state = REFRESH;
            end
            // While in pausestate, continue to monitor the refresh_timer
            // but do not increment it as we are not in a normal operation state
            //refresh_timer_en = 1'b0;
        end
          

    endcase
end

endmodule
