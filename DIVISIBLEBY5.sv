/*
DIVISIBLE by 5

Case0: MOD0 (remainder =0 )Let the current number gives 0 by dividing with 5
	If input is 0 (5x)*2= 5x  [it will be in MOD0]
	If input is 1 (5x)*2+1 = 10x+1 [it will go to MOD1]
Case1: MOD1 (remainder =1 )Let the current number gives 1 by dividing with 5
	If input is 0 (5x+1)*2= 5x+2  [it will be in MOD2]
	If input is 1 (5x+1)*2+1 = 10x+3 [it will go to MOD3]
Case2: MOD2 (remainder =2 )Let the current number gives 2 by dividing with 5
	If input is 0 (5x+2)*2= 5x+4  [it will be in MOD4]
	If input is 1 (5x+2)*2+1 = 10x+5 [it will go to MOD0]
Case3: MOD3 (remainder =3 )Let the current number gives 3 by dividing with 5
	If input is 0 (5x+3)*2= 10x+1  [it will be in MOD1]
	If input is 1 (5x+3)*2+1 = 10x+2 [it will go to MOD2]
Case4: MOD4 (remainder =4 )Let the current number gives 4by dividing with 5
	If input is 0 (5x+4)*2= 5x+3  [it will be in MOD3]
	If input is 1 (5x+4)*2+1 = 10x+4 [it will go to MOD4]
Only when the remainder is 0(State MOD0) the output will be 1 
*/
//Code
module model (
  input clk,
  input resetn,
  input din,
  output logic dout
);
enum logic [2:0] {MODR,MOD0,MOD1,MOD2,MOD3,MOD4} pstate,nstate;
always_ff @(posedge clk) begin 
  if(!resetn) pstate<=MODR;
  else        pstate<=nstate;
end 
always_comb begin 
  case(pstate) 
  MODR: nstate = din? MOD1 : MOD0;
  MOD0: nstate = din? MOD1 : MOD0;
  MOD1: nstate = din? MOD3 : MOD2;
  MOD2: nstate = din? MOD0 : MOD4;
  MOD3: nstate = din? MOD2 : MOD1;
  MOD4: nstate = din? MOD4 : MOD3;
  endcase
end 
assign dout = pstate==MOD0;
Endmodule


//TB
module tb;
  logic clk,resetn,din,dout;
  
  initial begin 
    clk = 0;
    resetn=1;din = 0;repeat(3) @(posedge clk);
    resetn=0;din = 0;repeat(3) @(posedge clk);
    resetn=1;din = 0;repeat(3) @(posedge clk);
    din = 1; repeat(3) @(posedge clk);
    din = 0; repeat(1) @(posedge clk);
    din = 1; repeat(2) @(posedge clk);
    din = 0; repeat(1) @(posedge clk);
    din = 1; repeat(1) @(posedge clk);
    #10 $finish;
  end
  
  always #1 clk++;
    
  model dut(.*);
  
  initial begin 
    $dumpvars;
  end 
  

endmodule
