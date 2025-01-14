// Priority Encoder 
module Parameterised_Penc #(
  parameter N = 4,
  localparam N1 = $clog2(N)
)(
  input logic [N-1:0] I_ENC,
  output logic [N1-1:0] O_enc
);
  
  always_comb begin 
    O_enc = '0;
    for (int i = 0; i < N; i++) begin
      if (I_ENC[i]) begin
        O_enc = i;
        break; // Exit loop after finding the first set bit
      end
    end
  end 
  
endmodule 
