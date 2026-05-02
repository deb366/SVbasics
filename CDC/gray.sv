// ─────────────────────────────────────────
// SOURCE DOMAIN  (clk_A)
// ─────────────────────────────────────────

// Step 1 — define states in binary (normal coding)
typedef enum logic [2:0] {
    IDLE    = 3'd0,
    FETCH   = 3'd1,
    DECODE  = 3'd2,
    EXECUTE = 3'd3,
    MEM     = 3'd4,
    WB      = 3'd5
} state_t;

state_t current_state;

// Step 2 — convert to gray code before crossing
// Formula: gray = binary XOR (binary >> 1)
// This is a pure combinational conversion
logic [2:0] state_gray;
assign state_gray = current_state ^ (current_state >> 1);

// Step 3 — register the gray code in source domain
// (never put raw combo logic directly into synchronizer)
logic [2:0] state_gray_reg;
always @(posedge clk_A or negedge rst_n) begin
    if (!rst_n) state_gray_reg <= 3'b000;
    else        state_gray_reg <= state_gray;
end

// Step 4 — now cross each bit through its own 2FF sync
// Safe! Because only 1 bit changes per transition
logic [2:0] state_gray_sync;

sync_2ff u_bit0 (.clk(clk_B), .d_in(state_gray_reg[0]), .d_out(state_gray_sync[0]));
sync_2ff u_bit1 (.clk(clk_B), .d_in(state_gray_reg[1]), .d_out(state_gray_sync[1]));
sync_2ff u_bit2 (.clk(clk_B), .d_in(state_gray_reg[2]), .d_out(state_gray_sync[2]));

// ─────────────────────────────────────────
// DESTINATION DOMAIN  (clk_B)
// ─────────────────────────────────────────

// Step 5 — convert gray back to binary
// Formula: binary[MSB] = gray[MSB]
//          binary[i]   = binary[i+1] XOR gray[i]
logic [2:0] state_binary_sync;

assign state_binary_sync[2] = state_gray_sync[2];
assign state_binary_sync[1] = state_binary_sync[2] ^ state_gray_sync[1];
assign state_binary_sync[0] = state_binary_sync[1] ^ state_gray_sync[0];

// Step 6 — now use normally in destination
always @(posedge clk_B) begin
    case (state_binary_sync)
        FETCH   : do_fetch_prep();
        EXECUTE : trigger_execution();
        WB      : latch_result();
    endcase
end
