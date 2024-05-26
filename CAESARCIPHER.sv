/*
if encrypt == 1, the B -> E, F->I 
if encrypt == 0, the E->B , I->F, B-> Z 
*/

module CaesarCipher(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in, // ASCII input character
    input logic encrypt,       // Encrypt/Decrypt selector (1 for encrypt, 0 for decrypt)
    output logic [7:0] data_out // ASCII output character
);
    // Define the shift amount
    parameter SHIFT = 3;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0; // Reset output
        end else begin
            if (data_in >= "A" && data_in <= "Z") begin // Only process uppercase letters
                if (encrypt) begin
                    // Encrypt: shift right
                    data_out <= (data_in - "A" + SHIFT) % 26 + "A";
                end else begin
                    // Decrypt: shift left
                    data_out <= (data_in - "A" + 26 - SHIFT) % 26 + "A";
                end
            end else begin
                // If input is not an uppercase letter, just pass it through
                data_out <= data_in;
            end
        end
    end
endmodule
