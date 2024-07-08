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

//++++++++++++++++++++++++++++++
// TEST BENCH 
//++++++++++++++++++++++++++++++
`timescale 1ns / 1ps

module tb_ProductionFSM();

    // Inputs to the FSM
    reg clk;
    reg rstn;
    reg start;
    reg assembly_done;
    reg quality_pass;
    reg quality_fail;
    reg packaging_done;
    reg error;
    reg maintenance;
    reg done_maintenance;
    reg inventory_check;

    // Output from the FSM
    wire [2:0] state;

    // Instantiate the FSM module
    ProductionFSM uut (
        .clk(clk),
        .rstn(rstn),
        .start(start),
        .assembly_done(assembly_done),
        .quality_pass(quality_pass),
        .quality_fail(quality_fail),
        .packaging_done(packaging_done),
        .error(error),
        .maintenance(maintenance),
        .done_maintenance(done_maintenance),
        .inventory_check(inventory_check),
        .state(state)
    );

    // Clock generation
    always #5 clk = ~clk;  // Generate a clock with a period of 10 ns

    // Test scenarios
    initial begin
        // Initialize all inputs
        clk = 0;
        rstn = 0;
        start = 0;
        assembly_done = 0;
        quality_pass = 0;
        quality_fail = 0;
        packaging_done = 0;
        error = 0;
        maintenance = 0;
        done_maintenance = 0;
        inventory_check = 0;

        // Reset the FSM
        #10 rstn = 1;
        //#10 reset = 1;

        // Progress to PACKAGING
        #20 start = 1; inventory_check = 1; // Start and check inventory
        #10 start = 0; 
        #20 assembly_done = 1; // Finish assembly
        #10 assembly_done = 0; quality_pass = 1; // Pass quality check
        #10 quality_pass = 0; packaging_done = 0; // Move to packaging
        #30 maintenance = 1; // Trigger maintenance during packaging
        #100 maintenance = 0; done_maintenance = 1; // Finish maintenance after 10 clock cycles
        #10 done_maintenance = 0; // Reset done_maintenance
        #20 packaging_done = 1; // Complete packaging
        #10 packaging_done = 0; // Move to dispatch
        #10;

        // Finish testing
        #10 $finish;
    end

    // Monitor state changes
    always @(posedge clk) begin
        $display("At time %t, State: %0d", $time, state);
    end
  initial begin 
    $dumpvars();
  end 

endmodule


