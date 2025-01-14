/*
As soon as the grant is given to a requester it should grant for atleast 2 clock cycles.
*/

module round_robin_arbiter_variable_time_slice(
		input clk,
		input rst_n,
		input [3:0] REQ,
		output reg[3:0] GNT
	
		);
	
  reg [1:0] count;
  reg [3:0] present_state;
  reg [3:0] next_state;
  parameter [3:0] S_ideal = 4'b0000;
  parameter [3:0] S_0 = 4'b0001;
  parameter [3:0] S_1 = 4'b0010;
  parameter [3:0] S_2 = 4'b0100;
  parameter [3:0] S_3 = 4'b1000;




  always @ (posedge clk or negedge rst_n) // State Register, Sequential always block

		begin
      if(!rst_n)

				present_state <= S_ideal;
			else
				present_state <= next_state;
		end

	always @(present_state or next_state or REQ) // Next State Logic , Combinational always
		begin
			case(present_state)
				S_ideal : begin
							count = 2'b00;
							if(REQ[0])
								begin
									next_state = S_0;
								end
							else if(REQ[1])
								begin
									next_state = S_1;
								end
							else if(REQ[2])
								begin
									next_state = S_2;
								end
							else if(REQ[3])
								begin
									next_state = S_3;
								end
						end

				S_0 : begin
						if(REQ[0])
							begin
                              if(count == 2'b10)
									begin
										if(REQ[1])
											begin
												count = 2'b00;
												next_state = S_1;
											end
										else if(REQ[2])
											begin
												count = 2'b00;
												next_state = S_2;
											end
										else if(REQ[3])
											begin
												count = 2'b00;
												next_state = S_3;
											end
										else
											begin
												count = 2'b00;
												next_state = S_0;
											end

									end // if(count = 2'b11)
						    	 else
									   count = count + 1'b1;
							 		   next_state = S_0;
							end // if(REQ[0])
						else if(REQ[1])
							begin
								count = 2'b00;
								next_state = S_1;
							end
						else if(REQ[2])
							begin
								count = 2'b00;
								next_state = S_2;
							end
						else if(REQ[3])
							begin
								count = 2'b00;
								next_state = S_3;
							end
						else
							begin
								count = 2'b00;
								next_state = S_ideal;
							end
					end // S_0
				S_1 : begin
						if(REQ[1])
							begin
                              if(count == 2'b10)
									begin
										if(REQ[2])
											begin
												count = 2'b00;
												next_state = S_2;
											end
										else if(REQ[3])
											begin
												count = 2'b00;
												next_state = S_3;
											end
										else if(REQ[0])
											begin
												count = 2'b00;
												next_state = S_0;
											end
										else
											begin
												count = 2'b00;
												next_state = S_1;
											end
										end // if(count = 2'b11)
									else
										count = count + 1'b1;
										next_state = S_1;
								end // if(REQ[1])
							else if(REQ[2])
								begin
									count = 2'b00;
									next_state = S_2;
								end
							else if(REQ[3])
								begin
									count = 2'b00;
									next_state = S_3;
								end
							else if(REQ[0])
								begin
									count = 2'b00;
									next_state = S_0;
								end
							else
						  		begin
									count = 2'b00;
									next_state = S_ideal;
								end
						end // S_1
					S_2 : begin
							if(REQ[2])
								begin
                                  if(count == 2'b10)
										begin
											if(REQ[3])
												begin
													count = 2'b00;
													next_state = S_3;
												end
											else if(REQ[0])
												begin
													count = 2'b00;
													next_state = S_0;
												end
											else if(REQ[1])
												begin
													count = 2'b00;
													next_state = S_1;
												end
											else
												begin
													count = 2'b00;
													next_state = S_2;
												end
                                        end // if(count = 2'b10)
									else
										count = count + 1'b1;
										next_state = S_2;
								end // if(REQ[2])
							else if(REQ[3])
									begin
										count = 2'b00;
										next_state = S_3;
									end
							else if(REQ[0])
									begin
										count = 2'b00;
										next_state = S_0;
									end
							else if(REQ[1])
									begin
										count = 2'b00;
										next_state = S_1;
									end
							else
									begin
										count = 2'b00;
										next_state = S_ideal;
									end
						end // S_2
					S_3 : begin
							if(REQ[3])
								begin
                                  if(count == 2'b10)
										begin
											if(REQ[0])
												begin
													count = 2'b00;
													next_state = S_0;
													end
											else if(REQ[1])
												begin
													count = 2'b00;
													next_state = S_1;
												end
											else if(REQ[2])
												begin
													count = 2'b00;
													next_state = S_2;
													end
											else
												begin
													count = 2'b00;
													next_state = S_3;
												end
										end // if(count = 2'b11)
									else
										count = count + 1'b1;
										next_state = S_3;
								end // if(REQ[3])
						else if(REQ[0])
								begin
									count = 2'b00;
									next_state = S_0;
								end
						else if(REQ[1])
								begin
									count = 2'b00;
									next_state = S_1;
								end
						else if(REQ[2])
								begin
									count = 2'b00;
									next_state = S_2;
								end
						else
								begin
									count = 2'b00;
									next_state = S_ideal;
								end
						end // S_3
			default : begin
							count = 2'b00;
						 if(REQ[0])
							begin
								next_state = S_0;
							end
						else if(REQ[1])
							begin
								next_state = S_1;
							end
						else if(REQ[2])
							begin
								next_state = S_2;
							end
						else if(REQ[3])
							begin
								next_state = S_3;
							end
					end
				endcase
			end

  always @(posedge clk or negedge rst_n) // Sequential Registered Output Logic (Glitch Free)
			begin
          if(!rst_n)
            begin
              GNT <= 4'b0000;
            end
          else
         	case(present_state)
					S_0 : begin GNT <= 4'b0001; end
					S_1 : begin GNT <= 4'b0010; end
					S_2 : begin GNT <= 4'b0100; end
					S_3 : begin GNT <= 4'b1000; end
				default : begin GNT <= 4'b0000; end
			endcase
		end
endmodule // Round Robin Arbiter with Variable Slice Time
