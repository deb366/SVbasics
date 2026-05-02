module cdc_pulse_toggle (
    input  logic clk_fast,
    input  logic rst_n,

    input  logic clk_slow,

    input  logic pulse_in,     // fast domain pulse
    output logic pulse_out     // slow domain pulse
);

    // ================================
    // Source domain (fast)
    // ================================
    logic toggle_src;

    always_ff @(posedge clk_fast or negedge rst_n) begin
        if (!rst_n)
            toggle_src <= 1'b0;
        else if (pulse_in)
            toggle_src <= ~toggle_src;
    end

    // ================================
    // Destination domain (slow)
    // ================================
    (* ASYNC_REG = "TRUE" *) logic toggle_sync1;
    (* ASYNC_REG = "TRUE" *) logic toggle_sync2;
    logic toggle_sync3;

    always_ff @(posedge clk_slow or negedge rst_n) begin
        if (!rst_n) begin
            toggle_sync1 <= 1'b0;
            toggle_sync2 <= 1'b0;
            toggle_sync3 <= 1'b0;
        end else begin
            toggle_sync1 <= toggle_src;
            toggle_sync2 <= toggle_sync1;
            toggle_sync3 <= toggle_sync2;
        end
    end

    // Edge detection
    assign pulse_out = toggle_sync2 ^ toggle_sync3;

endmodule
