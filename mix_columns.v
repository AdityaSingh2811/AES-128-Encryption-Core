`timescale 1ns / 1ps


// Module: mix_columns
//
// Description:
// Performs the MixColumns transformation on the entire 128-bit AES state.

module mix_columns (
    input  [127:0] in_state,  // The state after the ShiftRows step
    output [127:0] out_state  // The state after the MixColumns step
);

    
    // 1. Helper Wires for Galois Field Multiplication
    
    wire [7:0] b_x2 [0:15]; // Holds the result of byte * 2
    wire [7:0] b_x3 [0:15]; // Holds the result of byte * 3

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GF_MULTIPLIERS
            wire [7:0] current_byte = in_state[i*8 +: 8];
            wire [7:0] shifted_byte = {current_byte[6:0], 1'b0};
            assign b_x2[i] = current_byte[7] ? (shifted_byte ^ 8'h1B) : shifted_byte;
            assign b_x3[i] = b_x2[i] ^ current_byte;
        end
    endgenerate

    
    // 2. Column Mixing Logic (CORRECTED)
    //
    // The correct matrix formula for one column {a0, a1, a2, a3} is:
    // b0 = (a0*2) ^ (a1*3) ^ a2     ^ a3
    // b1 = a0     ^ (a1*2) ^ (a2*3) ^ a3
    // b2 = a0     ^ a1     ^ (a2*2) ^ (a3*3)
    // b3 = (a0*3) ^ a1     ^ a2     ^ (a3*2)
    
    wire [31:0] out_col0, out_col1, out_col2, out_col3;

    // --- Column 0 Processing (Bytes 0, 1, 2, 3) ---
    assign out_col0 = {
        b_x3[0] ^ in_state[8*1+:8] ^ in_state[8*2+:8] ^ b_x2[3], // b3
        in_state[8*0+:8] ^ in_state[8*1+:8] ^ b_x2[2] ^ b_x3[3], // b2
        in_state[8*0+:8] ^ b_x2[1] ^ b_x3[2] ^ in_state[8*3+:8], // b1
        b_x2[0] ^ b_x3[1] ^ in_state[8*2+:8] ^ in_state[8*3+:8]  // b0
    };

    // --- Column 1 Processing (Bytes 4, 5, 6, 7) ---
    assign out_col1 = {
        b_x3[4] ^ in_state[8*5+:8] ^ in_state[8*6+:8] ^ b_x2[7], // b3
        in_state[8*4+:8] ^ in_state[8*5+:8] ^ b_x2[6] ^ b_x3[7], // b2
        in_state[8*4+:8] ^ b_x2[5] ^ b_x3[6] ^ in_state[8*7+:8], // b1
        b_x2[4] ^ b_x3[5] ^ in_state[8*6+:8] ^ in_state[8*7+:8]  // b0
    };

    // --- Column 2 Processing (Bytes 8, 9, 10, 11) ---
    assign out_col2 = {
        b_x3[8] ^ in_state[8*9+:8]  ^ in_state[8*10+:8] ^ b_x2[11], // b3
        in_state[8*8+:8] ^ in_state[8*9+:8]  ^ b_x2[10] ^ b_x3[11], // b2
        in_state[8*8+:8] ^ b_x2[9]  ^ b_x3[10] ^ in_state[8*11+:8], // b1
        b_x2[8] ^ b_x3[9]  ^ in_state[8*10+:8] ^ in_state[8*11+:8]  // b0
    };

    // --- Column 3 Processing (Bytes 12, 13, 14, 15) ---
    assign out_col3 = {
        b_x3[12] ^ in_state[8*13+:8] ^ in_state[8*14+:8] ^ b_x2[15], // b3
        in_state[8*12+:8] ^ in_state[8*13+:8] ^ b_x2[14] ^ b_x3[15], // b2
        in_state[8*12+:8] ^ b_x2[13] ^ b_x3[14] ^ in_state[8*15+:8], // b1
        b_x2[12] ^ b_x3[13] ^ in_state[8*14+:8] ^ in_state[8*15+:8]  // b0
    };

    
    // 3. Final Output Assembly
    
    assign out_state = {out_col3, out_col2, out_col1, out_col0};

endmodule

