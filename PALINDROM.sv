//Palindrom number (101,11011,1001

module model #(parameter
  DATA_WIDTH=32
) (
  input [DATA_WIDTH-1:0] din,
  output logic dout
);
logic [DATA_WIDTH-1:0] w_temp;
always_comb begin 
 for(int i = 0; i< DATA_WIDTH ; i++ )begin 
  w_temp[i] = din[i] == din[DATA_WIDTH-1-i];
 end
end 
assign dout = &w_temp;
endmodule
)
