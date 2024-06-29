/*
The module will take 8bit input , and gives 32bit output the output is the total count of the specific input number and the number itself.
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


//The below code gives the output with sorted array 
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
                        items[j+1].value = items[j].value;
                    
                    	tmp_id = items[j].id;
                    	items[j].id = items[j+1].id;
                    	items[j+1].id = items[j].id;
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
