// Full handshake with consumption acknowledgment
module cdc_handshake_load #(
    parameter STATE_WIDTH = 8
) (
    // Source domain
    input  logic                     clk_src,
    input  logic                     rst_n_src,
    input  logic                     src_valid,        // pulse: new state is ready
    input  logic [STATE_WIDTH-1:0]   src_state,        // state to transfer
    output logic                     src_ready,        // pulse: handshake complete

    // Destination domain
    input  logic                     clk_dst,
    input  logic                     rst_n_dst,
    input  logic                     dst_load,         // pulse: previous state was consumed
    output logic                     dst_valid,        // pulse: new state is stable and available
    output logic [STATE_WIDTH-1:0]   dst_state
);
    // -----------------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------------
    logic req_src, req_dst;          // request
    logic ack_src, ack_dst;          // acknowledge
    logic pending_ack;               // set when data latched, cleared when dst_load arrives

    // =================================================================
    // SOURCE SIDE: drive req and monitor ack
    // =================================================================
    always_ff @(posedge clk_src or negedge rst_n_src) begin
        if (!rst_n_src) begin
            req_src   <= 1'b0;
            src_ready <= 1'b0;
        end else begin
            src_ready <= 1'b0;        // default pulse

            if (src_valid && !req_src) begin
                // New data available, raise request
                req_src <= 1'b1;
            end else if (ack_src) begin
                // Acknowledge received, clear request and signal ready
                req_src   <= 1'b0;
                src_ready <= 1'b1;
            end
        end
    end

    // =================================================================
    // SYNCHRONIZE req TO DESTINATION DOMAIN
    // =================================================================
    cdc_bit_sync #() u_sync_req (
        .clk_dst (clk_dst),
        .rst_n   (rst_n_dst),
        .sig_src (req_src),
        .sig_dst (req_dst)
    );

    // =================================================================
    // DESTINATION SIDE: latch data, wait for dst_load, then ack
    // =================================================================
    always_ff @(posedge clk_dst or negedge rst_n_dst) begin
        if (!rst_n_dst) begin
            dst_state   <= '0;
            dst_valid   <= 1'b0;
            ack_dst     <= 1'b0;
            pending_ack <= 1'b0;
        end else begin
            // One-shot pulse for dst_valid
            dst_valid <= 1'b0;

            // 1. Acknowledge only after consumption (dst_load) when data was waiting
            if (dst_load && pending_ack) begin
                ack_dst     <= 1'b1;
                pending_ack <= 1'b0;
            end

            // 2. Sample new state when request is high and we are not busy
            if (req_dst && !pending_ack && !ack_dst) begin
                dst_state   <= src_state;
                dst_valid   <= 1'b1;
                pending_ack <= 1'b1;      // now waiting for dst_load
            end

            // 3. Deassert ack once the request is no longer present
            if (!req_dst && ack_dst) begin
                ack_dst <= 1'b0;
            end
        end
    end

    // =================================================================
    // SYNCHRONIZE ack BACK TO SOURCE DOMAIN
    // =================================================================
    cdc_bit_sync #() u_sync_ack (
        .clk_dst (clk_src),
        .rst_n   (rst_n_src),
        .sig_src (ack_dst),
        .sig_dst (ack_src)
    );
Endmodule




