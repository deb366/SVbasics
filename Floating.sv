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
    assign mant_single = exp_half == 0 ? 0 : {mant_half, 13'b0};  // Zero or denormal else pad 0 at the lsb

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

//+++++++++++++++++++++++++++++++++++++++++++++++++//
//FP32(1s,8e,23m) to FP16 (1s,5e,10m)
//+++++++++++++++++++++++++++++++++++++++++++++++++//
module fp32_to_fp16(
    input logic [31:0] fp32,   // Input single precision float
    output logic [15:0] fp16   // Output half precision float
);

    // Extract parts of the single precision floating point
    wire s = fp32[31];  // Sign bit
    wire [7:0] exp32 = fp32[30:23];  // Exponent
    wire [22:0] mant32 = fp32[22:0];  // Mantissa

    // Variables for half precision
    logic [4:0] exp16;
    logic [9:0] mant16;

    // Handle exponent overflow/underflow and bias adjustment
    integer exp_adjusted;
    always_comb begin
        exp_adjusted = exp32 - 127 + 15;  // Adjust bias from 127 (FP32) to 15 (FP16)

        if (exp_adjusted > 31) begin
            // Overflow, set to max exponent and zero mantissa (infinity)
            exp16 = 31;
            mant16 = 0;
        end else if (exp_adjusted < 0) begin
            // Underflow, set to zero (denormals not handled)
            exp16 = 0;
            mant16 = 0;
        end else begin
            exp16 = exp_adjusted[4:0];  // Safe to cast since we've handled overflow/underflow
            // Simple truncation for mantissa
            mant16 = mant32[22:13];  // Take the most significant 10 bits
        end
    end

    // Compose the half precision floating point number
    assign fp16 = {s, exp16, mant16};

endmodule

//+++++++++++++++++++++++++++++++++++++++++++++++++//
//FP64(1s,11e,52m) to FP16(1s,5e,10m)
//+++++++++++++++++++++++++++++++++++++++++++++++++//
module fp64_to_fp16(
    input logic [63:0] fp64,   // Input double precision float
    output logic [15:0] fp16   // Output half precision float
);

    // Extract parts of the double precision floating point
    wire s = fp64[63];  // Sign bit
    wire [10:0] exp64 = fp64[62:52];  // Exponent
    wire [51:0] mant64 = fp64[51:0];  // Mantissa

    // Variables for half precision
    logic [4:0] exp16;
    logic [9:0] mant16;

    // Handle exponent overflow/underflow and bias adjustment
    integer exp_adjusted;
    always_comb begin
        exp_adjusted = exp64 - 1023 + 15;  // Adjust bias from 1023 (FP64) to 15 (FP16)

        if (exp_adjusted > 31) begin
            // Overflow, set to max exponent and zero mantissa (infinity)
            exp16 = 31;
            mant16 = 0;
        end else if (exp_adjusted < 0) begin
            // Underflow, set to zero (denormals not handled)
            exp16 = 0;
            mant16 = 0;
        end else begin
            exp16 = exp_adjusted[4:0];  // Safe to cast since we've handled overflow/underflow
            // Simple truncation for mantissa
            mant16 = mant64[51:42];  // Take the most significant 10 bits
        end
    end

    // Compose the half precision floating point number
    assign fp16 = {s, exp16, mant16};

endmodule

