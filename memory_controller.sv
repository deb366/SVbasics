// Design a parameterized memory controller module that interfaces with external memory devices (e.g., DDR SDRAM) and supports read, write, and refresh operations. 
//The controller should handle address mapping, data buffering, and timing constraints.


module memory_controller #(
    parameter ADDR_WIDTH = 28,
    parameter DATA_WIDTH = 64,
    parameter REFRESH_INTERVAL = 7800
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

typedef enum logic [2:0] {
    IDLE,
    READ,
    WRITE,
    REFRESH,
    WAIT,
    REFRESH_PAUSE
} mem_state_t;

mem_state_t current_state, next_state;

// Internal registers
logic [DATA_WIDTH-1:0] buffer;
logic [ADDR_WIDTH-1:0] current_addr;
logic refresh_timer_en;
integer refresh_timer;
logic refresh_pending;  // Flag to indicate refresh is needed

// Sequential logic for state transitions
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        current_addr <= '0;
        buffer <= '0;
        refresh_timer <= 0;
        refresh_pending <= 1'b0;
    end else begin
        current_state <= next_state;
        
        // Store address and data when starting operations
        if (current_state == IDLE) begin
            if (read_en) begin
                current_addr <= addr;
            end else if (write_en) begin
                current_addr <= addr;
                buffer <= write_data;
            end
        end
        
        // Refresh timer logic
        if (refresh_timer_en) begin
            if (refresh_timer >= REFRESH_INTERVAL) begin
                refresh_pending <= 1'b1;
                refresh_timer <= 0;
            end else begin
                refresh_timer <= refresh_timer + 1;
            end
        end
        
        // Reset refresh pending after refresh
        if (current_state == REFRESH) begin
            refresh_pending <= 1'b0;
        end
    end
end

// Combinational logic for next state and outputs
always_comb begin
    // Default outputs
    next_state = current_state;
    ready = 1'b0;
    ddr_read_en = 1'b0;
    ddr_write_en = 1'b0;
    ddr_refresh = 1'b0;
    ddr_addr = current_addr;
    ddr_data_in = buffer;
    refresh_timer_en = 1'b1;
    
    case (current_state)
        IDLE: begin
            if (refresh_pending && !pause_refresh) begin
                next_state = REFRESH;
            end else if (refresh_pending && pause_refresh) begin
                next_state = REFRESH_PAUSE;
            end else if (read_en) begin
                next_state = READ;
            end else if (write_en) begin
                next_state = WRITE;
            end
        end
        
        READ: begin
            ddr_read_en = 1'b1;
            next_state = WAIT;
        end
        
        WRITE: begin
            ddr_write_en = 1'b1;
            next_state = WAIT;
        end
        
        REFRESH: begin
            ddr_refresh = 1'b1;
            next_state = WAIT;
        end
        
        WAIT: begin
            // In a real implementation, we would wait for memory acknowledgment
            // For simplicity, we'll transition back to IDLE after one cycle
            ready = 1'b1;
            next_state = IDLE;
        end
        
        REFRESH_PAUSE: begin
            refresh_timer_en = 1'b0; // Pause refresh timer
            
            if (!pause_refresh) begin
                // Resume normal operation if pause is deasserted
                next_state = IDLE;
            end else if (refresh_timer >= REFRESH_INTERVAL * 2) begin
                // Emergency refresh if paused for too long
                next_state = REFRESH;
            end
            // Otherwise, stay in REFRESH_PAUSE
        end
    endcase
end

// Capture read data
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_data <= '0;
    end else if (ddr_read_en) begin
        read_data <= ddr_data_out;
    end
end

endmodule
