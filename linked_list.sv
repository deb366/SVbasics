/*
The code needs updates for pop operation.
*/

module linked_list #(parameter DATA_WIDTH = 8, SIZE = 10)
(
    input wire clk,
    input wire rstn,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire insert,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Define node structure within the array
    typedef struct packed {
      logic [31:0] data;
      logic [31:0] next;  // Index of the next node
    } node_t;

    // Array to hold nodes, simulating the linked list
    //reg [DATA_WIDTH+31:0] list[SIZE-1:0];
    node_t alist[SIZE-1:0];
    reg [31:0] head;
  reg [31:0] free_ptr,new_node;  // Points to the first free index (node)

    // Initialize the linked list
    always_ff @(posedge clk) begin
      if (!rstn) begin
            head <= -1;  // Indicates an empty list
            free_ptr <= 0;  // Start of the free list
            new_node <= 0;
            for (int i = 0; i < SIZE; i++) begin
              alist[i].next = (i < (SIZE - 1)) ? i + 1 : -1;
            end
        end 
      else if (insert) begin
            if (free_ptr != -1) begin
                new_node <= free_ptr;  // Allocate a new node from the free list
                free_ptr <= alist[new_node].next;  // Update free pointer
                alist[new_node].data <= data_in;  // Set new node data
                alist[new_node].next <= head;  // New node points to the previous head
                head = new_node;  // Head points to the new node
            end
        end
    end

    // Output the data at the head of the list
    always @* begin
        if (head != -1) 
            data_out = alist[head].data;
        else 
            data_out = 0;  // Return 0 if the list is empty
      end
  
endmodule

//+++++++++++++++++++ TB ++++++++++++++++++++//



//++++++++++++++++++++++
module linked_list_tb;
    reg clk;
    reg rstn;
    reg [7:0] data_in; // Assuming DATA_WIDTH is 8
    reg insert;

    // Assuming the linked_list has an output, declare it
    wire [7:0] data_out; 

    // Instantiate the DUT
    linked_list #( .DATA_WIDTH(8), .SIZE(10)) dut (
        .clk(clk),
        .rstn(rstn),
        .data_in(data_in),
        .insert(insert),
        .data_out(data_out) // Connect this if it's actually used in the DUT
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset and test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rstn = 0;
        data_in = 0;
        insert = 0;

        // Reset sequence
        repeat (10) @(posedge clk);
        rstn = 1;

        // Test sequence
        @(posedge clk) begin data_in = $urandom % 256; insert = 1; end
        @(posedge clk) begin data_in = $urandom % 256; insert = 0; end
        @(posedge clk) begin data_in = $urandom % 256; insert = 1; end
        @(posedge clk) begin data_in = $urandom % 256; insert = 1; end
        
        repeat (10) @(posedge clk);
        $finish;
    end
  initial begin 
    $dumpvars();
  end 
endmodule

