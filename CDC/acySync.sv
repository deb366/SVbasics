// =============================================================
// FILE: reset_sync.sv
// PURPOSE: Synchronize async reset release to a target clock
// FIXES: reset_unsync02 violations
// =============================================================

module reset_sync #(
    parameter STAGES = 2    // Number of sync stages (min 2)
)(
    input  logic clk,
    input  logic async_rst_n,   // Asynchronous reset input
    output logic sync_rst_n     // Synchronized reset output
);
    logic [STAGES-1:0] sync_chain;

    // Assertion: asynchronous (immediate, glitch-free)
    // Deassertion: synchronous (2 clock cycles after async release)
    always_ff @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            sync_chain <= '0;
        else
            sync_chain <= {sync_chain[STAGES-2:0], 1'b1};
    end

    assign sync_rst_n = sync_chain[STAGES-1];

    // Synthesis attribute to preserve synchronizer FFs
    // Prevents tool from optimizing them away
    (* DONT_TOUCH = "true" *) logic unused;
    assign unused = |sync_chain;  // Dummy use to preserve

endmodule

// =============================================================
// FILE: req_ack_sender.sv
// CLOCK DOMAIN: ACLK
// PURPOSE: Drives REQ-ACK handshake, holds data stable during transfer
// CDC CROSSINGS:
//   OUT: req_toggle → BCLK domain (synchronized by receiver)
//   IN:  ack_sync   ← BCLK domain (synchronized inside this module)
// =============================================================

module req_ack_sender #(
    parameter DATA_WIDTH = 8
)(
    // ACLK domain ports
    input  logic                  aclk,
    input  logic                  arst_n,        // Async reset, ACLK domain

    // Upstream producer interface (ACLK domain)
    input  logic                  src_valid,     // Producer has data
    output logic                  src_ready,     // Sender ready to accept
    input  logic [DATA_WIDTH-1:0] src_data,      // Data from producer

    // CDC interface — to/from BCLK domain
    output logic                  req_toggle,    // REQ: toggles on each new transaction
    input  logic                  ack_sync_in,   // ACK: already synchronized to ACLK
    output logic [DATA_WIDTH-1:0] data_out       // Data bus — held stable during handshake
);

    // ─── Internal State ────────────────────────────────────────
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        SEND    = 2'b01,
        WAIT_ACK= 2'b10,
        DONE    = 2'b11
    } sender_state_t;

    sender_state_t state, next_state;

    // Track previous ACK value for edge detection
    logic ack_prev;
    logic ack_edge_detected;

    // Synchronized reset
    logic arst_sync_n;

    // ─── Reset Synchronizer ────────────────────────────────────
    reset_sync #(.STAGES(2)) u_arst_sync (
        .clk        (aclk),
        .async_rst_n(arst_n),
        .sync_rst_n (arst_sync_n)
    );

    // ─── ACK Edge Detector ────────────────────────────────────
    // ACK uses toggle protocol — detect any toggle = ACK received
    always_ff @(posedge aclk or negedge arst_sync_n) begin
        if (!arst_sync_n)
            ack_prev <= 1'b0;
        else
            ack_prev <= ack_sync_in;
    end

    // Any change in ACK toggle = ACK received from receiver
    assign ack_edge_detected = (ack_sync_in != ack_prev);

    // ─── State Register ────────────────────────────────────────
    always_ff @(posedge aclk or negedge arst_sync_n) begin
        if (!arst_sync_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ─── Next State Logic ──────────────────────────────────────
    always_comb begin
        next_state = state;
        case (state)
            IDLE:     if (src_valid)           next_state = SEND;
            SEND:                              next_state = WAIT_ACK;
            WAIT_ACK: if (ack_edge_detected)   next_state = DONE;
            DONE:                              next_state = IDLE;
            default:                           next_state = IDLE;
        endcase
    end

    // ─── REQ Toggle Generator ─────────────────────────────────
    // Toggle REQ on entering SEND state — holds until ACK comes back
    always_ff @(posedge aclk or negedge arst_sync_n) begin
        if (!arst_sync_n)
            req_toggle <= 1'b0;
        else if (state == IDLE && next_state == SEND)
            req_toggle <= ~req_toggle;  // Toggle = new request
    end

    // ─── Data Register ────────────────────────────────────────
    // Latch data when starting SEND, hold stable throughout handshake
    // This is CRITICAL — data must not change while in BCLK domain
    always_ff @(posedge aclk or negedge arst_sync_n) begin
        if (!arst_sync_n)
            data_out <= '0;
        else if (state == IDLE && src_valid)
            data_out <= src_data;  // Capture once, hold stable
    end

    // ─── Outputs ──────────────────────────────────────────────
    assign src_ready = (state == IDLE || state == DONE);

endmodule


// =============================================================
// FILE: req_ack_receiver.sv
// CLOCK DOMAIN: BCLK
// PURPOSE: Receives REQ, captures data, drives ACK back
// CDC CROSSINGS:
//   IN:  req_toggle_in ← ACLK domain (synchronized inside here)
//   OUT: ack_toggle    → ACLK domain (synchronized by sender)
// =============================================================

module req_ack_receiver #(
    parameter DATA_WIDTH = 8
)(
    // BCLK domain ports
    input  logic                  bclk,
    input  logic                  brst_n,        // Async reset, BCLK domain

    // CDC interface — from/to ACLK domain
    input  logic                  req_toggle_in, // REQ: raw, needs synchronizing
    output logic                  ack_toggle,    // ACK: toggles after data captured
    input  logic [DATA_WIDTH-1:0] data_in,       // Data from sender (held stable)

    // Downstream consumer interface (BCLK domain)
    output logic                  dst_valid,     // Data valid to downstream
    input  logic                  dst_ready,     // Downstream can accept
    output logic [DATA_WIDTH-1:0] dst_data       // Captured data output
);

    // ─── Internal Signals ─────────────────────────────────────
    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        CAPTURE  = 2'b01,
        PRESENT  = 2'b10,
        SEND_ACK = 2'b11
    } receiver_state_t;

    receiver_state_t state, next_state;

    // 2-FF synchronizer chain for REQ
    logic req_sync_ff1, req_sync_ff2;
    logic req_prev;
    logic req_edge_detected;

    // Synchronized reset
    logic brst_sync_n;

    // ─── Reset Synchronizer ────────────────────────────────────
    reset_sync #(.STAGES(2)) u_brst_sync (
        .clk        (bclk),
        .async_rst_n(brst_n),
        .sync_rst_n (brst_sync_n)
    );

    // ─── 2-FF Synchronizer for REQ_TOGGLE (ACLK → BCLK) ──────
    // This is THE critical CDC synchronizer
    // SpyGlass must recognize this as a valid synchronizer cell
    // Pragma tells tool: "this is intentional CDC synchronization"

    (* DONT_TOUCH = "true" *)  // Preserve both FFs — no optimization
    always_ff @(posedge bclk or negedge brst_sync_n) begin
        if (!brst_sync_n) begin
            req_sync_ff1 <= 1'b0;
            req_sync_ff2 <= 1'b0;
        end else begin
            req_sync_ff1 <= req_toggle_in;  // First FF — may go metastable
            req_sync_ff2 <= req_sync_ff1;   // Second FF — resolved, safe
        end
    end

    // ─── REQ Edge (Toggle) Detector ───────────────────────────
    always_ff @(posedge bclk or negedge brst_sync_n) begin
        if (!brst_sync_n)
            req_prev <= 1'b0;
        else
            req_prev <= req_sync_ff2;
    end

    // Any toggle in synchronized REQ = new transaction from sender
    assign req_edge_detected = (req_sync_ff2 != req_prev);

    // ─── State Register ────────────────────────────────────────
    always_ff @(posedge bclk or negedge brst_sync_n) begin
        if (!brst_sync_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ─── Next State Logic ──────────────────────────────────────
    always_comb begin
        next_state = state;
        case (state)
            IDLE:     if (req_edge_detected)   next_state = CAPTURE;
            CAPTURE:                           next_state = PRESENT;
            PRESENT:  if (dst_ready)           next_state = SEND_ACK;
            SEND_ACK:                          next_state = IDLE;
            default:                           next_state = IDLE;
        endcase
    end

    // ─── Data Capture Register ────────────────────────────────
    // Capture data exactly ONE cycle after req_edge detected
    // At this point: sender guarantees data_in is STABLE
    // (sender entered WAIT_ACK and stopped driving new data)
    always_ff @(posedge bclk or negedge brst_sync_n) begin
        if (!brst_sync_n)
            dst_data <= '0;
        else if (state == CAPTURE)
            dst_data <= data_in;   // Safe to capture — sender holds it stable
    end

    // ─── ACK Toggle Generator ─────────────────────────────────
    // Toggle ACK after data captured — this crosses back to ACLK domain
    always_ff @(posedge bclk or negedge brst_sync_n) begin
        if (!brst_sync_n)
            ack_toggle <= 1'b0;
        else if (state == SEND_ACK)
            ack_toggle <= ~ack_toggle;  // Toggle = handshake complete
    end

    // ─── DST Valid ────────────────────────────────────────────
    assign dst_valid = (state == PRESENT || state == SEND_ACK);

endmodule



// =============================================================
// FILE: req_ack_top.sv
// PURPOSE: Wires sender + receiver, instantiates ACK synchronizer
//          back into ACLK domain
// CDC CROSSINGS SUMMARY:
//   1. req_toggle:  ACLK → BCLK  [synced inside receiver]
//   2. ack_toggle:  BCLK → ACLK  [synced inside this file]
//   3. data_bus:    ACLK → BCLK  [held stable, no sync needed]
// =============================================================

module req_ack_top #(
    parameter DATA_WIDTH = 8
)(
    // Clocks and resets
    input  logic                  aclk, arst_n,
    input  logic                  bclk, brst_n,

    // Producer side (ACLK)
    input  logic                  src_valid,
    output logic                  src_ready,
    input  logic [DATA_WIDTH-1:0] src_data,

    // Consumer side (BCLK)
    output logic                  dst_valid,
    input  logic                  dst_ready,
    output logic [DATA_WIDTH-1:0] dst_data
);

    // ─── Internal Wires ───────────────────────────────────────
    logic                  req_toggle;
    logic                  ack_toggle_bclk;   // Raw ACK in BCLK domain
    logic                  ack_sync_ff1;      // First stage of ACK sync
    logic                  ack_sync_aclk;     // Resolved ACK in ACLK domain
    logic [DATA_WIDTH-1:0] data_bus;          // Stable data from sender

    // Synchronized ACLK reset (for ACK synchronizer)
    logic                  arst_sync_n;

    reset_sync #(.STAGES(2)) u_ack_arst_sync (
        .clk        (aclk),
        .async_rst_n(arst_n),
        .sync_rst_n (arst_sync_n)
    );

    // ─── 2-FF Synchronizer: ACK_TOGGLE (BCLK → ACLK) ─────────
    (* DONT_TOUCH = "true" *)
    always_ff @(posedge aclk or negedge arst_sync_n) begin
        if (!arst_sync_n) begin
            ack_sync_ff1  <= 1'b0;
            ack_sync_aclk <= 1'b0;
        end else begin
            ack_sync_ff1  <= ack_toggle_bclk;  // May go metastable
            ack_sync_aclk <= ack_sync_ff1;     // Resolved — safe to use
        end
    end

    // ─── Sender Instance ──────────────────────────────────────
    req_ack_sender #(.DATA_WIDTH(DATA_WIDTH)) u_sender (
        .aclk        (aclk),
        .arst_n      (arst_n),
        .src_valid   (src_valid),
        .src_ready   (src_ready),
        .src_data    (src_data),
        .req_toggle  (req_toggle),
        .ack_sync_in (ack_sync_aclk),   // Synchronized ACK
        .data_out    (data_bus)
    );

    // ─── Receiver Instance ────────────────────────────────────
    req_ack_receiver #(.DATA_WIDTH(DATA_WIDTH)) u_receiver (
        .bclk         (bclk),
        .brst_n       (brst_n),
        .req_toggle_in(req_toggle),       // Raw REQ — synced inside
        .ack_toggle   (ack_toggle_bclk),  // Raw ACK — synced in top
        .data_in      (data_bus),
        .dst_valid    (dst_valid),
        .dst_ready    (dst_ready),
        .dst_data     (dst_data)
    );

endmodule

