//W I P 
// This module will take an instruction and will generate the output and a flag, after each WB state the ouput will be written in a memory location.

// Code your design here

module PipelinedProcessor #(parameter DATA_WIDTH = 32) (
    input logic clk,         // Clock input
    input logic rst_n,       // Active-low reset input
    input logic [DATA_WIDTH-1:0] instruction_in, // Input instruction
    input logic enable,      // Enable signal
    
    output logic [DATA_WIDTH-1:0] result_out // Output result
);

  logic w_stage_complete;
// Pipeline stages
typedef enum logic [1:0] {
    IF_STAGE,
    ID_STAGE,
    EX_STAGE,
    MEM_STAGE,
    WB_STAGE
} pipeline_stage_t;

// Internal signals
pipeline_stage_t current_stage, next_stage;
logic [DATA_WIDTH-1:0] operand1, operand2, result;
logic [5:0] opcode;

// Register file
logic [DATA_WIDTH-1:0] registers [15:0]; // 16 general-purpose registers

// Instruction memory (for simplicity, assuming synchronous memory)
logic [DATA_WIDTH-1:0] instruction_memory [1023:0];

// Instruction fetch stage
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_stage <= IF_STAGE;
    end else begin
        current_stage <= next_stage;
    end
end

// Instruction decode stage
always_comb begin
  w_stage_complete = 0
        case (current_stage)
            IF_STAGE: begin
                opcode = instruction_in[31:26];
                operand1 = instruction_in[25:21];
                operand2 = instruction_in[20:16];
                next_stage = ID_STAGE;
              	w_stage_complete = 0;
            end
            ID_STAGE: begin
                next_stage = EX_STAGE;
              	w_stage_complete = 0;
            end
            EX_STAGE: begin
                next_stage = MEM_STAGE;
              
                case (opcode)
            	// Arithmetic operations
            	6'b000000: result = operand1 + operand2; // ADD
            	6'b000010: result = operand1 - operand2; // SUB
            	6'b000100: result = operand1 & operand2; // AND
            	6'b000101: result = operand1 | operand2; // OR
            	// Control operations
            	6'b001000: result = (operand1 == operand2) ? 1 : 0; // Equality comparison
            	6'b001001: result = (operand1 != operand2) ? 1 : 0; // Inequality comparison
              	default:   result = 0;
                endcase                                    
              w_stage_complete = 0;
            end
            MEM_STAGE: begin
                next_stage = WB_STAGE;
              	w_stage_complete = 0;
              	
            end
            WB_STAGE: begin
                next_stage = IF_STAGE;
                w_stage_complete = 1;
            end
            default: begin
                next_stage = IF_STAGE;
            end
        endcase
    end

  always_ff @(posedge clk) begin 
    if(!rst_n)
      r_addr <= 0;
    else if(w_stage_complete)
      r_addr <= r_addr +1;
  end 


endmodule
