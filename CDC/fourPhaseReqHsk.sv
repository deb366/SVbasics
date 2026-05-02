
// ─────────────────────────────────────────────────────────
// REQ/ACK Handshake — complete module
// Transfers N-bit data safely from fast to slow domain
// ─────────────────────────────────────────────────────────
module handshake_fast_to_slow #(
    parameter DW = 32           // data width
)(
    // Source domain — clk_A (fast, 200MHz)
    input  logic          clk_A,
    input  logic          rst_n_A,
    input  logic [DW-1:0] src_data,     // data to transfer
    input  logic          src_valid,    // new data available (1-cycle pulse)
    output logic          src_busy,     // HIGH while transfer in progress

    // Destination domain — clk_B (slow, 50MHz)
    input  logic          clk_B,
    input  logic          rst_n_B,
    output logic [DW-1:0] dst_data,     // captured data — valid when dst_valid
    output logic          dst_valid     // 1-cycle pulse: new data captured
);

    // ── Internal signals ──────────────────────────────────
    logic [DW-1:0] data_latch;   // stable holding register in clk_A domain
    logic          req;          // REQ: clk_A → clk_B
    logic          ack;          // ACK: clk_B → clk_A

    logic          req_s1, req_s2;   // REQ sync in clk_B domain
    logic          ack_s1, ack_s2;   // ACK sync in clk_A domain

    // ── SOURCE DOMAIN STATE MACHINE (clk_A) ──────────────
    typedef enum logic [1:0] {
        SRC_IDLE    = 2'b00,
        SRC_LATCH   = 2'b01,   // latch data, assert REQ
        SRC_WAIT    = 2'b10,   // wait for ACK
        SRC_RELEASE = 2'b11    // deassert REQ after ACK
    } src_state_t;

    src_state_t src_state;

    always_ff @(posedge clk_A or negedge rst_n_A) begin
        if (!rst_n_A) begin
            src_state  <= SRC_IDLE;
            data_latch <= '0;
            req        <= 1'b0;
            src_busy   <= 1'b0;
        end
        else begin
            case (src_state)

                SRC_IDLE: begin
                    if (src_valid) begin
                        // Step 1: latch ALL data bits simultaneously
                        data_latch <= src_data;
                        src_busy   <= 1'b1;
                        src_state  <= SRC_LATCH;
                    end
                end

                SRC_LATCH: begin
                    // Step 2: assert REQ one cycle AFTER data is latched
                    // This guarantees data_latch is stable before REQ
                    req       <= 1'b1;
                    src_state <= SRC_WAIT;
                end

                SRC_WAIT: begin
                    // Step 3: wait for ACK to arrive from clk_B
                    if (ack_s2) begin
                        req       <= 1'b0;    // deassert REQ
                        src_state <= SRC_RELEASE;
                    end
                end

                SRC_RELEASE: begin
                    // Step 4: wait for ACK to deassert (4-phase complete)
                    if (!ack_s2) begin
                        src_busy  <= 1'b0;
                        src_state <= SRC_IDLE;
                    end
                end

            endcase
        end
    end

    // ── REQ crosses clk_A → clk_B ─────────────────────────
    always_ff @(posedge clk_B or negedge rst_n_B) begin
        if (!rst_n_B) {req_s2, req_s1} <= 2'b00;
        else          {req_s2, req_s1} <= {req_s1, req};
    end

    // ── ACK crosses clk_B → clk_A ─────────────────────────
    always_ff @(posedge clk_A or negedge rst_n_A) begin
        if (!rst_n_A) {ack_s2, ack_s1} <= 2'b00;
        else          {ack_s2, ack_s1} <= {ack_s1, ack};
    end

    // ── DESTINATION DOMAIN STATE MACHINE (clk_B) ──────────
    typedef enum logic [1:0] {
        DST_IDLE    = 2'b00,
        DST_CAPTURE = 2'b01,   // capture data, assert ACK
        DST_HOLD    = 2'b10,   // hold ACK until REQ deasserts
        DST_DONE    = 2'b11    // deassert ACK
    } dst_state_t;

    dst_state_t dst_state;
    logic       dst_valid_r;

    always_ff @(posedge clk_B or negedge rst_n_B) begin
        if (!rst_n_B) begin
            dst_state  <= DST_IDLE;
            dst_data   <= '0;
            ack        <= 1'b0;
            dst_valid_r<= 1'b0;
        end
        else begin
            dst_valid_r <= 1'b0;  // default: no new data

            case (dst_state)

                DST_IDLE: begin
                    if (req_s2) begin
                        // REQ arrived — data_latch guaranteed stable
                        // Sample ALL bits in this ONE cycle
                        dst_data    <= data_latch;
                        dst_valid_r <= 1'b1;   // pulse: new data ready
                        ack         <= 1'b1;   // assert ACK
                        dst_state   <= DST_HOLD;
                    end
                end

                DST_HOLD: begin
                    // Hold ACK until REQ deasserts (source saw ACK)
                    if (!req_s2) begin
                        ack       <= 1'b0;
                        dst_state <= DST_IDLE;
                    end
                end

            endcase
        end
    end

    assign dst_valid = dst_valid_r;

endmodule
