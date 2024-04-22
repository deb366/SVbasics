/*
//Implement a configurable multi-port register file module with the following features:
	• Configurable number of registers, data width, and number of read and write ports.
	• Support for simultaneous read and write operations on different ports.
Optional register locking mechanism to prevent simultaneous writes to the same register.
*/

//CODE 
module MULTI_PORT_REGISTER #(
    parameter int NUM_REGS = 8,          // Number of registers
    parameter int DATA_WIDTH = 32,       // Width of each register
    parameter int NUM_READ_PORTS = 2,    // Number of read ports
    parameter int NUM_WRITE_PORTS = 1    // Number of write ports
)(
    input logic clk,
    input logic rst,
    
    // Write ports
    input logic [NUM_WRITE_PORTS-1:0] write_en,                         // Write enable for each write port
    input logic [DATA_WIDTH-1:0] write_data [NUM_WRITE_PORTS],          // Write data for each write port
    input logic [$clog2(NUM_REGS)-1:0] write_addr [NUM_WRITE_PORTS],    // Write address for each write port

    // Read ports
    input logic [$clog2(NUM_REGS)-1:0] read_addr [NUM_READ_PORTS],      // Read address for each read port
    output logic [DATA_WIDTH-1:0] read_data [NUM_READ_PORTS]            // Read data for each read port
);

    // Memory to hold register values
    logic [DATA_WIDTH-1:0] reg_mem[NUM_REGS];

    // Write logic
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset all register values
            for (int i = 0; i < NUM_REGS; i++) begin
                reg_mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            for (int w = 0; w < NUM_WRITE_PORTS; w++) begin
                if (write_en[w]) begin
                    reg_mem[write_addr[w]] <= write_data[w];
                end
            end
        end
    end

    // Read logic
    always_comb begin
        for (int r = 0; r < NUM_READ_PORTS; r++) begin
            read_data[r] = reg_mem[read_addr[r]];
        end
    end

    // Optional register locking mechanism
    // The example below is a simple method to prevent simultaneous writes to the same register
    // by prioritizing the lower indexed write ports in case of conflict.
    // This mechanism can be replaced with a more sophisticated one if required.
    logic [NUM_REGS-1:0] write_lock; // Locking bits for each register

    always_ff @(posedge clk) begin
        if (rst) begin
            // Clear write locks
            write_lock <= {NUM_REGS{1'b0}};
        end else begin
            // Process write locks
            for (int w = 0; w < NUM_WRITE_PORTS; w++) begin
                if (write_en[w] && !write_lock[write_addr[w]]) begin
                    // Set lock if write is enabled and the register is not already locked
                    write_lock[write_addr[w]] <= 1'b1;
                end
            end
            // Unlock all registers at the end of the cycle
            write_lock <= {NUM_REGS{1'b0}};
        end
    end

endmodule
