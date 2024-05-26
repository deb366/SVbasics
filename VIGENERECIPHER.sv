/*
Let's choose the keyword "KEY" and use the plaintext "HELLO". 
Each letter in the plaintext is shifted by a number of positions defined by the corresponding letter in the keyword. 'A' = 0, 'B' = 1, 'C' = 2, ..., 'Y' = 24, 'Z' = 25.
H (7th letter of the alphabet) is shifted by K (10th letter), resulting in: (7+10)mod  26=17(7 + 10) \mod 26 = 17(7+10)mod26=17 which is R.
E (4th letter) is shifted by E (4th letter), resulting in: (4+4)mod  26=8(4 + 4) \mod 26 = 8(4+4)mod26=8 which is I.
L (11th letter) is shifted by Y (24th letter), resulting in: (11+24)mod  26=9(11 + 24) \mod 26 = 9(11+24)mod26=9 which is J.
L (11th letter) is shifted by K (10th letter), resulting in: (11+10)mod  26=21(11 + 10) \mod 26 = 21(11+10)mod26=21 which is V.
O (14th letter) is shifted by E (4th letter), resulting in: (14+4)mod  26=18(14 + 4) \mod 26 = 18(14+4)mod26=18 which is S.
so HELLO -> RIJVS
*/
//This has some syntax issue 


module VIGENERECIPHER(
    input logic clk,
    input logic rst_n,
    input logic encrypt,       // 1 for encrypt, 0 for decrypt
    input logic [7:0] data_in, // Input data (character)
    output logic [7:0] data_out // Output data (character)
);

    // Keyword for encryption and decryption (e.g., "KEY")
    parameter string KEY = "KEY";
    parameter int KEY_LENGTH = $strlen(KEY);
    integer i;

    logic [7:0] key_shifts[KEY_LENGTH];

    // Convert keyword to shift values
    initial begin
        for (i = 0; i < KEY_LENGTH; i++) begin
            key_shifts[i] = KEY[i] - 'A'; // Shift value from 'A'
        end
    end

    // State to keep track of current position in keyword
    reg [31:0] key_index;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_index <= 0;
            data_out <= 0;
        end else begin
            if (data_in >= "A" && data_in <= "Z") begin // Only process uppercase letters
                if (encrypt) begin
                    // Encrypt: Add key shift
                    data_out <= ((data_in - 'A' + key_shifts[key_index]) % 26) + 'A';
                end else begin
                    // Decrypt: Subtract key shift
                    data_out <= ((data_in - 'A' + 26 - key_shifts[key_index]) % 26) + 'A';
                end
                // Move to the next character in the keyword
                key_index <= (key_index + 1) % KEY_LENGTH;
            end else begin
                // Non-alphabetic characters are passed through unchanged
                data_out <= data_in;
            end
        end
    end
endmodule
