/*
Here the 1bit input comes and shift the rest to left by 1bit.
If X is a vector an din=0 the final vector becomes 2x, if din=1 the final vector becomes 2x+1 .
For divisible by 3 the remainder can be 0,1,2 
Case1: MOD0 (remainder =0 )Let the current number is divisible by 3 --> the output is 1
	If input is 0 3x*2= 6x [it will be in MOD0]
	If input is 1 3x*2+1 = 6x+1 [it will go to MOD1]
Case2: MOD1 (remainder =1 )Let the current number gives 1 by dividing with 3
	If input is 0 (3x+1)*2= 6x+2 [it will be in MOD2]
	If input is 1 (3x+1)*2+1 = 6x+3 [it will go to MOD0]
Case3: MOD2 (remainder =2 )Let the current number gives 2 by dividing with 3
	If input is 0 (3x+2)*2= 6x+4 [it will be in MOD1]
	If input is 1 (3x+2)*2+1 = 6x+5 [it will go to MOD2]
	
	Only when the remainder is 0(State MOD0) the output will be 1 
	*/
	
	
	//Code by Moore

module model (
  input clk,
  input resetn,
  input din,
  output logic dout
);
    parameter MODR=0, MOD0=1, MOD1=2, MOD2=3;
    logic [1:0] state;
    always @(posedge clk) begin
        if (!resetn) begin
            state <= MODR;
        end else begin
            case (state)
                MODR: state <= (din ? MOD1 : MOD0);
                MOD0: state <= (din ? MOD1 : MOD0);
                MOD1: state <= (din ? MOD0 : MOD2);
                MOD2: state <= (din ? MOD2 : MOD1);
            endcase
        end
    end
    assign dout = (state == MOD0);
endmodule
