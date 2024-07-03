//This is the logic for floating point inter conversions 

//+++++++++++++++++++++++++++++++++++++++++++++++++//
//Half(1s,5e,10m)  to Single precision(1s,8e,23m) 
//+++++++++++++++++++++++++++++++++++++++++++++++++//
module HalfToSingleConverter(
    input logic [15:0] half_precision,  // Half-precision input
    output logic [31:0] single_precision  // Single-precision output
);

    // Decompose half-precision input
    wire sign = half_precision[15];
    wire [4:0] exp_half = half_precision[14:10];
    wire [9:0] mant_half = half_precision[9:0];

    // Variables for single-precision output
    wire [7:0] exp_single;
    wire [22:0] mant_single;

    // Handle the exponent bias conversion and special cases
    assign exp_single = exp_half == 0 ? 0 :
                        exp_half == 31 ? 8'b11111111 :  // Handle half-precision infinity and NaN
                        exp_half + 112;  // Convert exponent from half to single (127 - 15)

    // Shift mantissa to align with single-precision format
    assign mant_single = exp_half == 0 ? 0 : {mant_half, 13'b0};  // Zero or denormal

    // Combine into single-precision format
    assign single_precision = {sign, exp_single, mant_single};

endmodule

//+++++++++++++++++++++++++++++++++++++++++++++++++//
//Half(1s,5e,10m) to Double precision(1s,11e,52m)
//+++++++++++++++++++++++++++++++++++++++++++++++++//

module HalfToDoubleConverter(
    input logic [15:0] half_precision,  // Half-precision input
    output logic [63:0] double_precision  // Double-precision output
);

    // Decompose half-precision input
    wire sign = half_precision[15];
    wire [4:0] exp_half = half_precision[14:10];
    wire [9:0] mant_half = half_precision[9:0];

    // Variables for double-precision output
    wire [10:0] exp_double;
    wire [51:0] mant_double;

    // Handle the exponent bias conversion and special cases
    assign exp_double = exp_half == 0 ? 0 :
                        exp_half == 31 ? 11'b11111111111 :  // Handle half-precision infinity and NaN
                        exp_half + 1008;  // Convert exponent from half to double (1023 - 15)

    // Shift mantissa to align with double-precision format
    assign mant_double = exp_half == 0 ? 0 : {mant_half, 42'b0};  // Zero or denormal

    // Combine into double-precision format
    assign double_precision = {sign, exp_double, mant_double};

endmodule
