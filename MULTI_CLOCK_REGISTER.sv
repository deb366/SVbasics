/*
There are 2 input streams: first is @500MHz and 1B per cycle and second is @250MHz at 3B per cycle. Find the frequency required with output at 2B per cycle. Also create u-arch f.or such design.
The read frequency is 625MHz
cal: lets assume we want to calculate 100clk of 500Mhz clk, at the time total of 100+50*3= 250B will be accumulated 
      we read by 2B, the read freq is fr
      100/500M = 125 * Tr  #both are unit of time
      Tr = 1/625M
      fr = 625MHz 
*/
//This code is not complete, the uArch is added with the same name

module MULTI_CLOCK_REGISTER (
    // First clock domain (1B write)
    input wire clk1,
    input wire rst1_n,
    input wire [7:0] data_in1,    // 1 byte input
    input wire write_en1,
  input wire [1:0] byte_addr1,  // which byte to write , can be anything 0..3
    
    // Second clock domain (3B write)
    input wire clk2,
    input wire rst2_n,
    input wire [23:0] data_in2,   // 3 bytes input
    input wire write_en2,
  input wire [1:0] start_byte2, // starting byte position, can be only 0,1 
    
    // Third clock domain (2B read)
    input wire clk3,
    input wire rst3_n,
    input wire read_en3,
    input wire [1:0] start_byte3, // starting byte position for reading
    output reg [15:0] data_out3   // 2 bytes output
);

    // Main storage register
    reg [31:0] storage;
  reg [7:0] storage1B;
  reg [23:0] storage3B;  

  
  
  always_ff @(posedge clk1 or negedge rst1_n) begin
        if (!rst1_n) begin
            storage1B <= 8'h0;
        end else if (write_en1) begin
            storage1B <= data_in1;
        end
    end
    
    // Clock domain 2: Writing 3B each clock
    always_ff @(posedge clk2 or negedge rst2_n) begin
        if (!rst2_n) begin
            storage3B <= 24'h0;
        end else if (write_en2) begin
            storage3B <= data_in2;
        end
    end  
    
  assign storage = start_byte2 ? {storage3B,storage1B} : {storage1B,storage3B};
  
    // Clock domain 3: Reading 2B each clock
    always_ff @(posedge clk3 or negedge rst3_n) begin
        if (!rst3_n) begin
            data_out3 <= 16'h0;
        end else if (read_en3) begin
            data_out3 <= storage[start_byte3*8 +: 16];
        end
    end

endmodule

