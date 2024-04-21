//Develop a configurable and scalable cache coherence protocol for a multi-core processor system, ensuring data consistency across shared memory regions. 
//Support features such as snooping-based
//The actual coherence protocol takes the consideration of 100s different system considerations, here the states and implementation are done using oversimplified manner 
/*
The MESI protocol is a well-known cache coherence protocol used in multiprocessor systems. 
It ensures consistency of the data stored in the local caches of a shared-memory system. MESI stands for the four states that a cache line can be in:

When the data first read to a CACHE is read it goes to EXCLUSIVE state. When the local processor writes that cache-line it goes to MODIFIED STATE. If some other processor sends a read 
request that cache-line, the first processor writes that data to Main Memory, after that the 2nd processor reads that data and both of these processor goes to SHARED state. After that if
any of the processor writes to that cache line, that processor goes to MODIFIED state and all other goes to INVALID state.

1. Modified (M):
Exclusive Ownership: The cache line is present only in the current cache and not in any other cache.
Dirty: The data has been modified (written to) by the local processor and is different from what is in main memory.
Write-back Required: Before this cache line can be read by another processor or evicted from the cache, the modified value must be written back to main memory to ensure coherence.
No Other Read or Write: No other processor can read or write this memory address until the modified data is written back and the state changes.

2. Exclusive (E):
Exclusive Ownership: The cache line is present only in the current cache and not in any other cache.
Clean: The data matches what is in main memory; it has not been modified by the local processor.
No Write-back Required: If the line is evicted from the cache, no write-back is required because the memory is still up-to-date.
Upgrade to Modified: If the local processor writes to the cache line, it can transition to the Modified state without needing to notify other processors.

3. Shared (S):
Non-exclusive Ownership: The cache line may be present in other caches.
Clean: The data matches what is in main memory; it has not been modified.
Read Sharing: Multiple processors can read from this cache line without causing any coherence actions.
Downgrade on Remote Write: If another processor writes to this address, this cache must invalidate its copy or fetch the updated value.

4. Invalid (I):
No Ownership: The cache line is not valid, which means it either contains no data or the data it contains should not be used.
Stale Data: The data in this cache line, if any, is not guaranteed to be up-to-date.
Fetching Required: If a processor needs to read this memory address, it must fetch the data from main memory or another cache.
State on Remote Modification: If another processor modifies data that this cache previously had in Shared or Exclusive state, this cache must set its state to Invalid.
*/

//CODE 
	module cache_controller #(
	    parameter integer CACHE_SIZE = 256,  // Number of cache lines
	    parameter integer DATA_WIDTH = 32,    // Width of data in bits
      	parameter integer WEIGHT_ADDR_WIDTH = 32
	) (
	    input logic clk,
	    input logic rst_n,
	    input logic [CACHE_SIZE-1:0] read_request,   // Read request lines from each core
	    input logic [CACHE_SIZE-1:0] write_request,  // Write request lines from each core
	    output logic [CACHE_SIZE-1:0] read_grant,    // Read grant lines to each core
	    output logic [CACHE_SIZE-1:0] write_grant,   // Write grant lines to each core
	    inout [DATA_WIDTH-1:0] bus_data,             // Data bus for snooping
	    input logic [CACHE_SIZE-1:0] bus_snoop ,      // Snooping lines to check if other caches have the line
	    output logic [CACHE_SIZE-1:0] write_back_request,
	    output logic [WEIGHT_ADDR_WIDTH-1:0] write_back_address[CACHE_SIZE-1:0] // Assuming a separate write-  //back address for each cache line 
	);
	
	
	    // Define the MESI protocol states
	    typedef enum logic [1:0] {
	        MESI_INVALID = 2'b00,
	        MESI_SHARED = 2'b01,
	        MESI_EXCLUSIVE = 2'b10,
	        MESI_MODIFIED = 2'b11
	    } mesi_state_t;
	
	    // Cache line struct including state and data
	    typedef struct packed {
	        mesi_state_t state;
	        logic [DATA_WIDTH-1:0] data;
	    } cache_line_t;
	
	    // Cache memory
	    cache_line_t cache [CACHE_SIZE-1:0];
	
	    // FSM for each cache line to handle coherence
	    always_ff @(posedge clk or negedge rst_n) begin
	        if (!rst_n) begin
	            // Initialize states to invalid on reset
	            for (int idx = 0; idx < CACHE_SIZE; idx++) begin
	                cache[idx].state <= MESI_INVALID;
	                cache[idx].data <= '0; // Clear cache data
		     write_back_request[idx] <= 1'b0; 
		     write_back_address[idx] <= '0; 
	            end
	
	        end else begin
	            for (int idx = 0; idx < CACHE_SIZE; idx++) begin
	                case (cache[idx].state)
	                    MESI_INVALID: begin
	                        if (read_request[idx]) begin
	                            // Move to SHARED if not being written elsewhere
	                            cache[idx].state <= MESI_SHARED;
	                            // Read data from memory or bus into cache line
	                        end else if (write_request[idx]) begin
	                            // Move to MODIFIED on a write
	                            cache[idx].state <= MESI_MODIFIED;
	                            // Data to be written to cache line
	                        end
	                    end
	                    MESI_SHARED: begin
	                        if (write_request[idx]) begin
	                            // Upgrade to MODIFIED on a write
	                            cache[idx].state <= MESI_MODIFIED;
	                            // Invalidate other caches' lines through snooping
	                        end else if (bus_snoop[idx]) begin
	                            // Invalidate if others are writing
	                            cache[idx].state <= MESI_INVALID;
	                        end
	                    end
	                    MESI_EXCLUSIVE: begin
	                        if (write_request[idx]) begin
	                            // Update data on write
	                            cache[idx].state <= MESI_MODIFIED;
	                        end else if (bus_snoop[idx]) begin
	                            // Downgrade to SHARED if others are reading
	                            cache[idx].state <= MESI_SHARED;
	                        end
	                    end
	                    MESI_MODIFIED: begin
	                        if (!write_request[idx]) begin
	                            // Write back if needed and move to EXCLUSIVE or SHARED
				write_back_request[idx] <= 1'b1; 
				write_back_address[idx] <= idx;
	                            if (bus_snoop[idx]) begin
	                                cache[idx].state <= MESI_SHARED;
	                            end else 
	                                cache[idx].state <= MESI_EXCLUSIVE;
	                            
	                            // Write data back to memory or share with bus
	                        end
	                    end
	                    default: cache[idx].state <= MESI_INVALID; // Fallback for undefined states
	                endcase
	            end
	        end
	    end
	
	    // Grant read and write access based on MESI state
	    assign read_grant = read_request & ~write_request; // Simplified for illustration
	    assign write_grant = write_request & ~read_request; // Simplified for illustration
	
	    // Example bus snooping response logic
	    // This is highly simplified and would need to be expanded for a real system
	    logic [CACHE_SIZE-1:0] bus_snoop_response;
	    assign bus_snoop_response = {CACHE_SIZE{1'b0}};
	
	endmodule
	


