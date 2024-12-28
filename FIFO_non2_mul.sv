//Here the DEPTH can be anything 

module FIFO_non2_mul #(
    parameter DEPTH = 5,
    parameter DATA_WIDTH = 16,             // 2 bytes = 16 bits
    parameter ADDR_WIDTH = $clog2(DEPTH)   // Will evaluate to 3 for depth of 5
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     wr_en,
    input  wire                     rd_en,
    input  wire [DATA_WIDTH-1:0]    wr_data,
    output reg  [DATA_WIDTH-1:0]    rd_data,
    output wire                     full,
    output wire                     empty,
    output wire [ADDR_WIDTH:0]      fifo_count // Extra bit to count up to DEPTH
);

    // Internal registers for FIFO memory and pointers
    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];  // Memory depth is now 5
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;

    // Assign output count
    assign fifo_count = count;

    // Full and empty flags
    assign full  = (count == DEPTH);  // Will be true when count = 5
    assign empty = (count == 0);

    // Write pointer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;  // Wraps at 4
        end
    end

    // Read pointer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;  // Wraps at 4
        end
    end

    // FIFO count logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en & !full, rd_en & !empty})
                2'b10:   count <= count + 1; // Write only
                2'b01:   count <= count - 1; // Read only
                2'b11:   count <= count;     // Read and write together
                default: count <= count;     // No change
            endcase
        end
    end

    // Write operation
    always @(posedge clk) begin
        if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= wr_data;
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr];
        end
    end

    // Synthesis assertions
    // synthesis translate_off
    always @(posedge clk) begin
        if (wr_en && full) begin
            $display("Warning: Write attempt to full FIFO at time %0t", $time);
        end
        if (rd_en && empty) begin
            $display("Warning: Read attempt from empty FIFO at time %0t", $time);
        end
    end
    // synthesis translate_on

endmodule
