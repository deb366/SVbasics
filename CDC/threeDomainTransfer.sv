
//SENDER 1 → clk_A domain (150 MHz) → produces signal_A 
//SENDER 2 → clk_C domain (200 MHz) → produces signal_C 
//RECEIVER → clk_B domain (100 MHz) → needs BOTH signal_A AND signal_C together in the SAME clk_B cycle

//In any REQ/ACK handshake across clock domains:

//You CANNOT deassert ACK until you have SEEN the source  deassert REQ.
//Why? Because the source only deasserts REQ after it has  seen ACK (via its own 2FF sync). If you deassert ACK before seeing REQ drop, the source may still be in the  middle of its WAIT_ACK state — it has not yet seen the  ACK, so it will never drop REQ, and the handshake hangs  forever (deadlock scenario).

//AND if your state machine loops back to IDLE before REQ  drops, you trigger a spurious second capture.

//Req from A and C  captured in B  ack to A and C  deassert the Req in A and C  deassert the ack in B


    // ================================================================
// MODULE  : three_domain_transfer
// PURPOSE : Safe transfer of signal_A (from clk_A domain) and
//           signal_C (from clk_C domain) to clk_B domain,
//           where both are used TOGETHER in the same logic.
//
// DOMAINS :
//   clk_A = 150 MHz  →  produces  signal_A  (DW_A bits wide)
//   clk_C = 200 MHz  →  produces  signal_C  (DW_C bits wide)
//   clk_B = 100 MHz  →  receives  both, captures in SAME cycle
//
// CDC ISSUE SOLVED :
//   Ac_conv02 — signals from completely different source domains
//   converging at destination. Without this module, independent
//   2FF syncs would let signal_A and signal_C arrive at clk_B
//   0..N cycles apart (unbounded skew). clk_B would see
//   signal_A=NEW while signal_C=OLD — reconvergence corruption.
//
// SOLUTION :
//   Each source domain latches its data into a STABLE REGISTER,
//   then sends a single REQ bit across a 2FF sync.
//   clk_B waits until BOTH req_A_sync AND req_C_sync are HIGH
//   in the SAME clk_B cycle before reading either data value.
//   At that point both data values are GUARANTEED frozen and
//   stable — captured atomically in ONE clk_B cycle.
// ================================================================

module three_domain_transfer #(
    parameter int DW_A = 16,   // width of signal_A
    parameter int DW_C = 16    // width of signal_C
)(
    // ── clk_A DOMAIN — sender of signal_A ───────────────────
    input  logic              clk_A,
    input  logic              rst_n_A,
    input  logic [DW_A-1:0]  signal_A,        // new value of signal_A
    input  logic              signal_A_valid,  // 1-cycle pulse: new data ready
    output logic              clk_A_busy,      // HIGH: transfer in progress

    // ── clk_C DOMAIN — sender of signal_C ───────────────────
    input  logic              clk_C,
    input  logic              rst_n_C,
    input  logic [DW_C-1:0]  signal_C,        // new value of signal_C
    input  logic              signal_C_valid,  // 1-cycle pulse: new data ready
    output logic              clk_C_busy,      // HIGH: transfer in progress

    // ── clk_B DOMAIN — receiver of both ─────────────────────
    input  logic              clk_B,
    input  logic              rst_n_B,
    output logic [DW_A-1:0]  captured_A,      // signal_A — valid when capture_valid=1
    output logic [DW_C-1:0]  captured_C,      // signal_C — valid when capture_valid=1
    output logic              capture_valid    // 1-cycle pulse: both captured this cycle
);

// ================================================================
// STEP 1 — STABLE HOLDING REGISTERS
// Each source domain freezes its data here BEFORE sending REQ.
// These cross to clk_B as raw wires — safe because REQ crossing
// through 2FF adds enough delay that data is always settled.
// ================================================================

    logic [DW_A-1:0] sig_A_stable;  // frozen in clk_A domain
    logic [DW_C-1:0] sig_C_stable;  // frozen in clk_C domain

// ================================================================
// STEP 2 — REQ/ACK CONTROL SIGNALS
// req crosses source → clk_B through 2FF (control path).
// ack crosses clk_B → source through 2FF (handshake return).
// ================================================================

    // REQ bits — asserted by source AFTER data is frozen
    logic req_A;   // lives in clk_A domain
    logic req_C;   // lives in clk_C domain

    // REQ synchronized into clk_B domain
    (* ASYNC_REG = "TRUE" *) logic req_A_ff1, req_A_ff2;
    (* ASYNC_REG = "TRUE" *) logic req_C_ff1, req_C_ff2;

    wire  req_A_sync;   // safe to use in clk_B domain
    wire  req_C_sync;   // safe to use in clk_B domain

    // ACK bits — asserted by clk_B AFTER capturing data
    logic ack_A;   // lives in clk_B domain
    logic ack_C;   // lives in clk_B domain

    // ACK synchronized back into source domains
    (* ASYNC_REG = "TRUE" *) logic ack_A_ff1, ack_A_ff2;
    (* ASYNC_REG = "TRUE" *) logic ack_C_ff1, ack_C_ff2;

    wire  ack_A_sync;   // safe to use in clk_A domain
    wire  ack_C_sync;   // safe to use in clk_C domain

// ================================================================
// SOURCE STATE MACHINE — clk_A DOMAIN (150 MHz)
//
// Sequence:
//   IDLE      : wait for signal_A_valid pulse
//   LATCH     : freeze signal_A into sig_A_stable
//   ASSERT    : assert req_A exactly 1 cycle after latch
//               (so sig_A_stable is already stable when REQ
//                starts propagating through 2FF sync)
//   WAIT_ACK  : wait for clk_B to acknowledge receipt
//   RELEASE   : deassert req_A, return to IDLE
// ================================================================

    typedef enum logic [2:0] {
        A_IDLE     = 3'b000,
        A_LATCH    = 3'b001,
        A_ASSERT   = 3'b010,
        A_WAIT_ACK = 3'b011,
        A_RELEASE  = 3'b100
    } fsm_A_t;

    fsm_A_t state_A;

    always_ff @(posedge clk_A or negedge rst_n_A) begin
        if (!rst_n_A) begin
            state_A      <= A_IDLE;
            sig_A_stable <= '0;
            req_A        <= 1'b0;
            clk_A_busy   <= 1'b0;
        end
        else begin
            case (state_A)

                A_IDLE : begin
                    req_A      <= 1'b0;
                    clk_A_busy <= 1'b0;
                    if (signal_A_valid) begin
                        clk_A_busy <= 1'b1;
                        state_A    <= A_LATCH;
                    end
                end

                A_LATCH : begin
                    // ── KEY STEP ──────────────────────────────
                    // All DW_A bits of signal_A captured simultaneously.
                    // sig_A_stable will NOT change until A_RELEASE.
                    // This is what makes the raw-wire crossing safe:
                    // by the time req_A propagates through 2FF in
                    // clk_B domain (~20ns at 100MHz), sig_A_stable
                    // has been frozen for those full 20ns.
                    // ──────────────────────────────────────────
                    sig_A_stable <= signal_A;
                    state_A      <= A_ASSERT;
                end

                A_ASSERT : begin
                    // req_A goes HIGH exactly 1 clk_A cycle after latch.
                    // Data is already stable. REQ now travels to clk_B.
                    req_A   <= 1'b1;
                    state_A <= A_WAIT_ACK;
                end

                A_WAIT_ACK : begin
                    // clk_B sends back ack_A when it has captured sig_A_stable.
                    // ack_A crosses through 2FF sync → ack_A_sync.
                    if (ack_A_sync) begin
                        req_A   <= 1'b0;    // deassert — begin 4-phase release
                        state_A <= A_RELEASE;
                    end
                end

                A_RELEASE : begin
                    // Wait for ack_A_sync to deassert (clk_B saw req_A go low).
                    // Only then is it safe to send new data.
                    if (!ack_A_sync) begin
                        clk_A_busy <= 1'b0;
                        state_A    <= A_IDLE;
                        // sig_A_stable can now accept a new value.
                    end
                end

            endcase
        end
    end

// ================================================================
// SOURCE STATE MACHINE — clk_C DOMAIN (200 MHz)
// Identical logic, completely independent from clk_A FSM.
// Runs at its own pace — clk_B waits for both independently.
// ================================================================

    typedef enum logic [2:0] {
        C_IDLE     = 3'b000,
        C_LATCH    = 3'b001,
        C_ASSERT   = 3'b010,
        C_WAIT_ACK = 3'b011,
        C_RELEASE  = 3'b100
    } fsm_C_t;

    fsm_C_t state_C;

    always_ff @(posedge clk_C or negedge rst_n_C) begin
        if (!rst_n_C) begin
            state_C      <= C_IDLE;
            sig_C_stable <= '0;
            req_C        <= 1'b0;
            clk_C_busy   <= 1'b0;
        end
        else begin
            case (state_C)

                C_IDLE : begin
                    req_C      <= 1'b0;
                    clk_C_busy <= 1'b0;
                    if (signal_C_valid) begin
                        clk_C_busy <= 1'b1;
                        state_C    <= C_LATCH;
                    end
                end

                C_LATCH : begin
                    // Freeze ALL bits of signal_C simultaneously.
                    // sig_C_stable held until C_RELEASE — raw wire safe.
                    sig_C_stable <= signal_C;
                    state_C      <= C_ASSERT;
                end

                C_ASSERT : begin
                    req_C   <= 1'b1;
                    state_C <= C_WAIT_ACK;
                end

                C_WAIT_ACK : begin
                    if (ack_C_sync) begin
                        req_C   <= 1'b0;
                        state_C <= C_RELEASE;
                    end
                end

                C_RELEASE : begin
                    if (!ack_C_sync) begin
                        clk_C_busy <= 1'b0;
                        state_C    <= C_IDLE;
                    end
                end

            endcase
        end
    end

// ================================================================
// 2FF SYNCHRONIZERS — CONTROL PATH ONLY
//
// NOTE: sig_A_stable and sig_C_stable cross as RAW WIRES.
//       They do NOT go through synchronizers. This is safe because:
//
//   sig_A_stable frozen at clk_A cycle T1
//   req_A asserted at clk_A cycle T2 = T1 + 1
//   req_A_sync arrives at clk_B cycle T4 (2-3 clk_B cycles later)
//
//   At T4: sig_A_stable has been frozen for T4 - T1
//          = (T2-T1) × T_clkA + 2 × T_clkB
//          = 1×6.7ns + 2×10ns = 26.7ns >> setup time
//          → GUARANTEED STABLE when clk_B reads it
//
//   Same reasoning applies to sig_C_stable via req_C_sync.
// ================================================================

    // req_A : clk_A → clk_B
    always_ff @(posedge clk_B or negedge rst_n_B) begin
        if (!rst_n_B) {req_A_ff2, req_A_ff1} <= 2'b00;
        else          {req_A_ff2, req_A_ff1} <= {req_A_ff1, req_A};
    end
    assign req_A_sync = req_A_ff2;

    // req_C : clk_C → clk_B
    always_ff @(posedge clk_B or negedge rst_n_B) begin
        if (!rst_n_B) {req_C_ff2, req_C_ff1} <= 2'b00;
        else          {req_C_ff2, req_C_ff1} <= {req_C_ff1, req_C};
    end
    assign req_C_sync = req_C_ff2;

    // ack_A : clk_B → clk_A
    always_ff @(posedge clk_A or negedge rst_n_A) begin
        if (!rst_n_A) {ack_A_ff2, ack_A_ff1} <= 2'b00;
        else          {ack_A_ff2, ack_A_ff1} <= {ack_A_ff1, ack_A};
    end
    assign ack_A_sync = ack_A_ff2;

    // ack_C : clk_B → clk_C
    always_ff @(posedge clk_C or negedge rst_n_C) begin
        if (!rst_n_C) {ack_C_ff2, ack_C_ff1} <= 2'b00;
        else          {ack_C_ff2, ack_C_ff1} <= {ack_C_ff1, ack_C};
    end
    assign ack_C_sync = ack_C_ff2;

// ================================================================
// DESTINATION STATE MACHINE — clk_B DOMAIN (100 MHz)
//
// THIS IS WHERE THE RECONVERGENCE IS ELIMINATED.
//
// clk_B does NOT act the moment either REQ arrives.
// It waits until BOTH req_A_sync AND req_C_sync are HIGH
// simultaneously in the SAME clk_B cycle.
//
// At that cycle:
//   sig_A_stable is frozen and stable  (guaranteed by req_A protocol)
//   sig_C_stable is frozen and stable  (guaranteed by req_C protocol)
//   Both captured in ONE always_ff block → same clock edge → zero skew
//
// Compare this to the BAD approach (independent 2FF syncs):
//   signal_A arrives at clk_B cycle 10 (via its own 2FF)
//   signal_C arrives at clk_B cycle 13 (via its own 2FF)
//   Cycles 10-12: clk_B sees signal_A=NEW, signal_C=OLD → WRONG
//   SpyGlass Ac_conv02 fires → silicon bug
// ================================================================

    typedef enum logic [1:0] {
        B_IDLE    = 2'b00,
        B_CAPTURE = 2'b01,
        B_HOLD    = 2'b10,
        B_DONE    = 2'b11
    } fsm_B_t;

    fsm_B_t state_B;

    always_ff @(posedge clk_B or negedge rst_n_B) begin
        if (!rst_n_B) begin
            state_B      <= B_IDLE;
            captured_A   <= '0;
            captured_C   <= '0;
            capture_valid<= 1'b0;
            ack_A        <= 1'b0;
            ack_C        <= 1'b0;
        end
        else begin
            capture_valid <= 1'b0;   // default low; pulse only on capture

            case (state_B)

                B_IDLE : begin
                    ack_A <= 1'b0;
                    ack_C <= 1'b0;
                    // ── THE RECONVERGENCE FIX ─────────────────
                    // Check BOTH req lines simultaneously.
                    // Only proceed when BOTH are confirmed 1.
                    //
                    // If req_A_sync=1 but req_C_sync=0 → WAIT.
                    // This cycle is skipped entirely.
                    // No data is read. No partial result produced.
                    //
                    // This prevents the "signal_A=NEW, signal_C=OLD"
                    // window that causes Ac_conv02 reconvergence.
                    // ─────────────────────────────────────────────
                    if (req_A_sync && req_C_sync)
                        state_B <= B_CAPTURE;
                end

                B_CAPTURE : begin
                    // ── ATOMIC CAPTURE ─────────────────────────
                    // Both sig_A_stable and sig_C_stable read in
                    // EXACTLY the same always_ff block.
                    // Synthesiser assigns them on the SAME clock edge.
                    // Absolute zero cycle skew between captured_A
                    // and captured_C. They are always coherent.
                    // ─────────────────────────────────────────────
                    captured_A    <= sig_A_stable;   // raw wire — stable guaranteed
                    captured_C    <= sig_C_stable;   // raw wire — stable guaranteed
                    capture_valid <= 1'b1;           // 1-cycle pulse to downstream
                    ack_A         <= 1'b1;           // tell clk_A: data received
                    ack_C         <= 1'b1;           // tell clk_C: data received
                    state_B       <= B_HOLD;
                end

                B_HOLD : begin
                    // Hold ACKs until both source domains see them
                    // and deassert their REQ lines.
                    // We wait for BOTH to drop (4-phase completion).
                    if (!req_A_sync && !req_C_sync)
                        state_B <= B_DONE;
                end

                B_DONE : begin
                    // Deassert ACKs — handshake fully complete.
                    // Sources will see ack_X_sync drop and return to IDLE.
                    ack_A   <= 1'b0;
                    ack_C   <= 1'b0;
                    state_B <= B_IDLE;
                end

            endcase
        end
    end

endmodule

8.10	QACTIVE then QACCPEPTN code:

// IP domain — correct sequencing
always @(posedge ip_clk) begin
    case (q_state)
        IDLE: begin
            QACTIVE   <= 0;
            if (!qreqn_sync) q_state <= WAIT_ACTIVE_CLEAR;
        end
        WAIT_ACTIVE_CLEAR: begin
            idle_delay <= idle_delay + 1;
            // Wait 3 cycles after QACTIVE=0 before asserting QACCEPTN
            if (idle_delay == 3) begin
                QACCEPTN  <= 0;  // now safe to assert accept
                q_state   <= ACCEPTED;
            end
        end
    endcase
end


