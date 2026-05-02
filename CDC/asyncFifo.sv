
// ─────────────────────────────────────────────────────────
// Async FIFO — gray-coded pointer synchronization
// Full implementation for fast-to-slow crossing
// ─────────────────────────────────────────────────────────
module async_fifo #(
    parameter DW    = 32,    // data width
    parameter DEPTH = 16     // must be power of 2
)(
    // Write port — clk_A (fast source, 200MHz)
    input  logic          wr_clk,
    input  logic          wr_rst_n,
    input  logic [DW-1:0] wr_data,
    input  logic          wr_en,
    output logic          wr_full,

    // Read port — clk_B (slow dest, 50MHz)
    input  logic          rd_clk,
    input  logic          rd_rst_n,
    output logic [DW-1:0] rd_data,
    input  logic          rd_en,
    output logic          rd_empty,

    // Optional — almost full/empty for flow control
    output logic          wr_almost_full,
    output logic          rd_almost_empty
);
    localparam AWIDTH = $clog2(DEPTH);   // address width
    localparam PWIDTH = AWIDTH + 1;      // pointer width (1 extra bit for full/empty)

    // ── Memory array (no clock domain — just a RAM) ───────
    logic [DW-1:0] mem [0:DEPTH-1];

    // ── Write domain pointers (clk_A) ─────────────────────
    logic [PWIDTH-1:0] wr_ptr_bin;   // binary write pointer
    logic [PWIDTH-1:0] wr_ptr_gray;  // gray-coded write pointer

    // ── Read domain pointers (clk_B) ──────────────────────
    logic [PWIDTH-1:0] rd_ptr_bin;   // binary read pointer
    logic [PWIDTH-1:0] rd_ptr_gray;  // gray-coded read pointer

    // ── Cross-domain synchronized pointers ────────────────
    (* ASYNC_REG = "TRUE" *) logic [PWIDTH-1:0] wptr_s1_rdclk, wptr_s2_rdclk;
    (* ASYNC_REG = "TRUE" *) logic [PWIDTH-1:0] rptr_s1_wrclk, rptr_s2_wrclk;

    // ── Binary to Gray conversion ─────────────────────────
    function automatic [PWIDTH-1:0] bin2gray(input [PWIDTH-1:0] bin);
        return bin ^ (bin >> 1);
    endfunction

    // ── Gray to Binary conversion ─────────────────────────
    function automatic [PWIDTH-1:0] gray2bin(input [PWIDTH-1:0] gray);
        logic [PWIDTH-1:0] bin;
        bin[PWIDTH-1] = gray[PWIDTH-1];
        for (int i = PWIDTH-2; i >= 0; i--)
            bin[i] = bin[i+1] ^ gray[i];
        return bin;
    endfunction

    // ── WRITE DOMAIN LOGIC (clk_A) ────────────────────────
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
        end
        else if (wr_en && !wr_full) begin
            mem[wr_ptr_bin[AWIDTH-1:0]] <= wr_data;   // write to RAM
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1'b1);
        end
    end

    // ── Sync read pointer into write domain (clk_A) ───────
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) {rptr_s2_wrclk, rptr_s1_wrclk} <= '0;
        else           {rptr_s2_wrclk, rptr_s1_wrclk} <= {rptr_s1_wrclk, rd_ptr_gray};
    end

    // Full flag in write domain
    // Full when write pointer has lapped read pointer
    // Gray comparison: top 2 bits differ, rest same
    logic [PWIDTH-1:0] rptr_bin_in_wrclk;
    assign rptr_bin_in_wrclk = gray2bin(rptr_s2_wrclk);
    assign wr_full = (wr_ptr_bin[PWIDTH-1]   != rptr_bin_in_wrclk[PWIDTH-1]) &&
                     (wr_ptr_bin[AWIDTH-1:0]  == rptr_bin_in_wrclk[AWIDTH-1:0]);
    assign wr_almost_full = (wr_ptr_bin[AWIDTH-1:0] - rptr_bin_in_wrclk[AWIDTH-1:0] >= DEPTH-2);

    // ── READ DOMAIN LOGIC (clk_B) ─────────────────────────
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
        end
        else if (rd_en && !rd_empty) begin
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1'b1);
        end
    end

    // ── Sync write pointer into read domain (clk_B) ───────
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) {wptr_s2_rdclk, wptr_s1_rdclk} <= '0;
        else           {wptr_s2_rdclk, wptr_s1_rdclk} <= {wptr_s1_rdclk, wr_ptr_gray};
    end

    // Empty flag in read domain
    logic [PWIDTH-1:0] wptr_bin_in_rdclk;
    assign wptr_bin_in_rdclk = gray2bin(wptr_s2_rdclk);
    assign rd_empty = (rd_ptr_bin == wptr_bin_in_rdclk);
    assign rd_almost_empty = (wptr_bin_in_rdclk - rd_ptr_bin <= 2);

    // ── Read data output ──────────────────────────────────
    assign rd_data = mem[rd_ptr_bin[AWIDTH-1:0]];

endmodule

// ─────────────────────────────────────────────────────────
// Usage — streaming data 200MHz → 50MHz
// ─────────────────────────────────────────────────────────
module top_streaming (
    input  logic        clk_A, clk_B, rst_n,
    input  logic [31:0] data_in,
    input  logic        data_valid,    // new data each clk_A cycle
    output logic [31:0] data_out,
    output logic        data_avail
);
    logic fifo_full, fifo_empty;

    async_fifo #(.DW(32), .DEPTH(16)) u_fifo (
        .wr_clk   (clk_A),
        .wr_rst_n (rst_n),
        .wr_data  (data_in),
        .wr_en    (data_valid & ~fifo_full),
        .wr_full  (fifo_full),
        .rd_clk   (clk_B),
        .rd_rst_n (rst_n),
        .rd_data  (data_out),
        .rd_en    (~fifo_empty),
        .rd_empty (fifo_empty)
    );

    assign data_avail = ~fifo_empty;

endmodule
