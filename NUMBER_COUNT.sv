/*
The module will take 8bit input , and gives 32bit output the output is the total count of the specific input number and the number itself. lets the input is 
ABDAA2  the output will be 3 and A.
	Sol:
	We need a [255:0][7:0] RAM for this, at the very next clk of input change the RAM's input position will be added with 1. At the next clk the RAM's updated position will be read to give the output. 
*/
	module count_numbers(
	  input logic clk,rstn,
	  input logic [7:0] I_NUM,
	  output logic [7:0] O_NUM,
	  output logic [7:0] O_CNT
	);
	  
	  logic [255:0][7:0] r_ram;
	  logic [7:0] r_inum;
	  
	  always_ff @(posedge clk)begin 
	    if(!rstn)begin 
	      r_ram <= '0;
	      r_inum <= '0;
	    end
	    
	    else begin 
	      r_ram[I_NUM] <= r_ram[I_NUM] + 1'b1;
	      r_inum <= I_NUM;      
	    end    
	  end
	  
	  assign O_NUM = r_inum;
	  assign O_CNT = r_ram[r_inum];
	  
	  
	endmodule 

//++++++++++++++++++++++++++++++++++++++++++++++++//
//The below code gives the output with sorted array 
//++++++++++++++++++++++++++++++++++++++++++++++++//
module count_numbers(
  input logic clk,rstn,
  input logic [7:0] I_NUM,
  input logic sortit,
  output logic [7:0] O_NUM,
  output logic [7:0] O_CNT,
  output logic [7:0] O_MAX_REQUEST_ID,
  output logic [7:0] O_MAX_REQUEST_NUM
);
	  
	  //logic [255:0][7:0] r_ram;
      logic [7:0] r_ram[256];
      //logic [255:0][7:0] w_sort_ram;
	  logic [7:0] r_inum;
      logic [7:0] tmp;
      logic [7:0] tmp_id;
	  
  always_ff @(posedge clk)begin 
	if(!rstn)begin 
          r_ram <= '{default:8'h0};
	  r_inum <= '0;
	end
	    
	else begin 
	  r_ram[I_NUM] <= r_ram[I_NUM] + 1'b1;
	  r_inum <= I_NUM;      
	end    
  end
	  
integer i, j;
typedef struct packed {
        logic [7:0] id;
        logic [7:0] value;
} items_t;
      
items_t items[256];
	  
always_comb begin
        if (sortit) begin
            // Bubble sort algorithm
          for(i = 0;i<256;i++) begin 
            items[i].id = i;
            items[i].value = r_ram[i]; 
          end 
        	//w_sort_ram = r_ram;
        	//integer i, j;
          	for (i = 255; i > -1; i--) begin
            	for (j = 0; j < i; j++) begin
                  if (items[j].value < items[j + 1].value) begin
                        tmp = items[j].value;
                    	items[j].value = items[j+1].value;
                        items[j+1].value = tmp;
                    
                    	tmp_id = items[j].id;
                    	items[j].id = items[j+1].id;
                    	items[j+1].id = tmp_id;
                    end 
                end
            end
        end
end
      
assign O_NUM = r_inum;
assign O_CNT = r_ram[r_inum];
assign O_MAX_REQUEST_ID = items[0].id;
assign O_MAX_REQUEST_NUM = items[0].value;
      
endmodule 

//---------------------------//
//-------Test Bench ---------//
//---------------------------//

`timescale 1ns/1ps

module tb_count_numbers;

  // Interface signals
  logic clk;
  logic rstn;
  logic [7:0] I_NUM;
  logic sortit;
  logic [7:0] O_NUM;
  logic [7:0] O_CNT;
  logic [7:0] O_MAX_REQUEST_ID;
  logic [7:0] O_MAX_REQUEST_NUM;

  // Instantiate the DUT
  count_numbers dut (
    .clk(clk),
    .rstn(rstn),
    .I_NUM(I_NUM),
    .sortit(sortit),
    .O_NUM(O_NUM),
    .O_CNT(O_CNT),
    .O_MAX_REQUEST_ID(O_MAX_REQUEST_ID),
    .O_MAX_REQUEST_NUM(O_MAX_REQUEST_NUM)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Testbench class declarations
  class Transaction;
    rand logic [7:0] num;
    rand bit sort;

    constraint c_num { num inside {[0:255]}; }
  endclass

  class Generator;
    Transaction txn;

    function new();
      txn = new();
    endfunction

    virtual task generate1(input logic en_sort);
      txn.randomize();
      txn.sort = en_sort;
    endtask
  endclass

  class Monitor;
    logic [7:0] observed_num;
    logic [7:0] observed_count;

    function new();
    endfunction

    virtual task capture(input logic [7:0] num, input logic [7:0] cnt);
      observed_num = num;
      observed_count = cnt;
    endtask
  endclass

  class Scoreboard;
    logic [7:0] ram[256];
    logic [7:0] max_id;
    logic [7:0] max_val;

    function new();
      foreach (ram[i]) ram[i] = 8'd0;
    endfunction

    virtual task update(input logic [7:0] num);
      ram[num]++;
    endtask

    virtual function void validate(input logic sort, input logic [7:0] id, input logic [7:0] val);
      if (sort) begin
        max_id = 0;
        max_val = 0;
        foreach (ram[i]) begin
          if (ram[i] > max_val) begin
            max_val = ram[i];
            max_id = i;
          end
        end

        assert(id == max_id && val == max_val)
          else $fatal("Validation failed: Expected id=%0d, val=%0d, Got id=%0d, val=%0d", max_id, max_val, id, val);
      end
    endfunction
  endclass

  // Testbench components
  Generator gen;
  Monitor mon;
  Scoreboard sb;

  // Test initialization,
  initial begin
    gen = new();
    mon = new();
    sb = new();

    rstn = 0;
    I_NUM = 8'd0;
    sortit = 0;
    #20 rstn = 1;

    // Test sequence
    repeat (100) begin
      gen.generate1($urandom_range(0, 1));
      @(posedge clk);
      I_NUM = gen.txn.num;
      sortit = gen.txn.sort;
      @(posedge clk);

      sb.update(I_NUM);

      if (sortit) begin
        @(posedge clk);
        sb.validate(sortit, O_MAX_REQUEST_ID, O_MAX_REQUEST_NUM);
      end
    end

    $display("Test completed successfully.");
    $finish;
  end
        
  initial begin 
    $dumpvars;        
  end 

endmodule

