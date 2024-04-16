//The I_LOAD should be pulse, if the O_STALL is high the host should not send new data and should keep the I_LOAD as 0

module Parallel2Serial #(parameter N = 4, localparam N0 = $clog2(N)) (
  input logic clk,rstn, input logic [N-1:0] I_PDATA, input logic I_LOAD, output logic O_STALL,O_SERIAL);
  logic [N-1:0] r_temp;
  logic [N0-1:0] r_cnt;
  logic r_load;
  
always_ff @(posedge clk) begin 
  if(!rstn) begin 
    r_temp <='0;
    r_cnt <='0;
  end 
  else if (I_LOAD && !r_load) begin //the I_LOAD should be a pulse 
    r_temp <= I_PDATA;
    r_cnt <= '0;
    r_load <= I_LOAD;
  end 
  else if(r_load)begin 
    r_temp <= r_temp >> 1;
    r_cnt <= r_cnt + 1;
  end 
  else if(r_cnt == N-2) begin
    r_load <= 0;
  end 
end

  assign O_STALL = r_load && (r_cnt< N);
//assign O_VALID = r_cnt< N;

assign O_SERIAL = r_temp[0];
  
endmodule 
