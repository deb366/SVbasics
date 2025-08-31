//Dot product of 6 numbers  a0b0+a1b1+a2b2
module model (
    input [7:0] din,
    input clk,
    input resetn,
    output reg [17:0] dout,
    output reg run
);

    reg [2:0] cnt;
    //reg [7:0] mem [5:0];
    reg  [5:0] [7:0] mem;
    reg [15:0] a1b1, a2b2, a3b3;
    // A 3-bit counter is used to track the number of inputs
    always_ff @(posedge clk) begin
        if (!resetn || cnt == 5) begin
            cnt <= 0;
        end else begin 
            cnt <= cnt + 1;
        end
    end
    // Internal memory
    always_ff @(posedge clk) begin
        if (!resetn) begin
            mem <= {6{8'h0}};
        end 
        else begin
            mem[cnt] <= din;
        end
    end
    // Combinational logic, aibi is initialised to 0 implicitely 
    assign run = (cnt == 0);
    assign a1b1 = (run) ? mem[0] * mem[3] : a1b1;
    assign a2b2 = (run) ? mem[1] * mem[4] : a2b2;
    assign a3b3 = (run) ? mem[2] * mem[5] : a3b3;
    assign dout = a1b1 + a2b2 + a3b3;
endmodule
