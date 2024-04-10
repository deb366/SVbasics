//OneHot Based FSM 
//The SV code can be written in 2 ways by forward,by reverse case statements 
	//1. Forward Case 

	enum logic [2:0] {RED = 3'b001,
	GREEN = 3'b010,
	YELLOW = 3'b100,
	BAD_STATE = 3'bxxx,
	} State, Next;
	
	case (State)
	 RED: Next = GREEN;
	 GREEN: Next = YELLOW;
	 YELLOW: Next = RED;
	 default:Next = BAD_STATE;
	Endcase
	
	//2. Reverse Case
	enum {R_BIT = 0, G_BIT = 1,Y_BIT = 2} state_bit;
	enum logic [2:0] {RED = 3'b001<<R_BIT,GREEN = 3'b001<<G_BIT,YELLOW = 3'b001<<Y_BIT} State, Next;
	
	always_comb begin: set_next_state
	Next = 3’b000; // clear Next - ERROR: ILLEGAL ASSIGNMENT
	unique case (1’b1) // reversed case statement
	// WARNING: FOLLOWING ASSIGNMENTS ARE POTENTIAL DESIGN ERRORS
		State[R_BIT]: if (sensor == 1) Next[G_BIT] = 1’b1;
		State[G_BIT]: if (green_downcnt==0) Next[Y_BIT] = 1’b1;
		State[Y_BIT]: if (yellow_downcnt==0) Next[R_BIT] = 1’b1;
	endcase
end: set_next_state
