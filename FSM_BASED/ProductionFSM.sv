/*
Automated Production Line Control
Problem: Implement an FSM in SystemVerilog to control an automated production line that processes multiple product types. The FSM should manage different stages of production, such as assembly, quality check, packaging, and dispatch.

Specifications:
Different production paths based on product type.
Error handling for production faults.
Integration with inventory management for raw materials.
Handling of pause and resume features for maintenance.
Stages include feedback loops for quality assurance.
*/
module ProductionFSM(
    input logic clk,
    input logic rstn,
    input logic start,
    input logic assembly_done,
    input logic quality_pass,
    input logic quality_fail,
    input logic packaging_done,
    input logic error,
    input logic maintenance,
    input logic done_maintenance,  // signal to handle exiting maintenance, it will go back to the originating state 
    input logic inventory_check,
    output logic[2:0] state
);
    typedef enum logic[2:0] {
        IDLE = 3'b000,
        INVENTORY = 3'b001,
        ASSEMBLY = 3'b010,
        QUALITY_CHECK = 3'b011,
        PACKAGING = 3'b100,
        DISPATCH = 3'b101,
        MAINTENANCE = 3'b110
    } state_t;

    state_t CSTATE, NSTATE, last_state; // last_state to remember the state before MAINTENANCE

    assign state = CSTATE;

    always_ff @(posedge clk) begin
      if (!rstn) begin
            CSTATE <= IDLE;
            last_state <= IDLE; // Reset last_state as well
        end else begin
            CSTATE <= NSTATE;
            if (maintenance && CSTATE != MAINTENANCE) begin
                last_state <= CSTATE; // Update last_state only when transitioning to MAINTENANCE
            end
        end
    end
  
    always_comb begin
        case (CSTATE)
            IDLE: NSTATE = start ? INVENTORY : IDLE;
            INVENTORY: NSTATE = maintenance ? MAINTENANCE : (inventory_check ? ASSEMBLY : INVENTORY);
            ASSEMBLY: NSTATE = maintenance ? MAINTENANCE : (assembly_done ? QUALITY_CHECK : ASSEMBLY);
            QUALITY_CHECK: NSTATE = maintenance ? MAINTENANCE : (quality_pass ? PACKAGING : QUALITY_CHECK);
            PACKAGING: NSTATE = maintenance ? MAINTENANCE : (packaging_done ? DISPATCH : PACKAGING);
            DISPATCH: NSTATE = maintenance ? MAINTENANCE : IDLE;
            MAINTENANCE: NSTATE = done_maintenance ? last_state : MAINTENANCE; // Return to the last state when maintenance is done
            //default: NSTATE = IDLE;
        endcase
    end
endmodule
