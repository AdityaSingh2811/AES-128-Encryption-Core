`timescale 1ns / 1ps


// Module: key_expansion
//
// Description:
// Generates the 11 round keys required for AES-128 encryption. This is a
// fully combinational, unrolled implementation that is efficient for hardware
// synthesis. The correct key is selected based on the 'round' input.

module key_expansion (
    input        [127:0] initial_key, // The original 128-bit key
    input        [3:0]   round,       // The current round number (0-10)
    output       [127:0] round_key    // The key for the specified round
);

   
    // 1. Internal Storage for all 11 Round Keys
   
    // We will store the keys as an array of 32-bit words.
    // 11 keys * 4 words/key = 44 words total.
    wire [31:0] w [0:43];

   
    // 2. The Round Constant (Rcon)
    // This is a special value that changes each round and is used to prevent
    // symmetries in the key schedule.
   
    reg [7:0] Rcon [1:10];
    initial begin
        Rcon[1]  = 8'h01; Rcon[2]  = 8'h02; Rcon[3]  = 8'h04; Rcon[4]  = 8'h08;
        Rcon[5]  = 8'h10; Rcon[6]  = 8'h20; Rcon[7]  = 8'h40; Rcon[8]  = 8'h80;
        Rcon[9]  = 8'h1B; Rcon[10] = 8'h36;
    end

   
    // 3. Key Generation Logic
    //
    // A fully combinational, unrolled implementation is the clearest and most
    // reliable for synthesis. The `generate` block creates 10 unique hardware
    // blocks, one for each round's key generation logic.
   
    genvar j;
    generate
        // Words 0-3 are the initial key (Round 0 Key)
        assign w[0] = initial_key[127:96];
        assign w[1] = initial_key[95:64];
        assign w[2] = initial_key[63:32];
        assign w[3] = initial_key[31:0];

        // Generate the logic for the next 10 round keys (Rounds 1-10)
        for (j = 1; j <= 10; j = j + 1) begin : KEY_GEN_ROUND
            // Wires for the g() function of this specific round
            wire [31:0] prev_word    = w[j*4 - 1];
            wire [31:0] rotated_word = {prev_word[23:16], prev_word[15:8], prev_word[7:0], prev_word[31:24]};
            wire [31:0] sub_word;
            wire [31:0] g_func_out;

            // Instantiate S-Boxes specifically for this round's g() function
            sbox sbox_inst_0 (.in_byte(rotated_word[31:24]), .out_byte(sub_word[31:24]));
            sbox sbox_inst_1 (.in_byte(rotated_word[23:16]), .out_byte(sub_word[23:16]));
            sbox sbox_inst_2 (.in_byte(rotated_word[15:8]),  .out_byte(sub_word[15:8]));
            sbox sbox_inst_3 (.in_byte(rotated_word[7:0]),   .out_byte(sub_word[7:0]));

            // XOR the substituted word with the round constant
            assign g_func_out = sub_word ^ {Rcon[j], 24'h0};

            // Calculate the 4 words for this round's key using the g() result
            assign w[j*4]     = w[j*4 - 4] ^ g_func_out;
            assign w[j*4 + 1] = w[j*4 - 3] ^ w[j*4];
            assign w[j*4 + 2] = w[j*4 - 2] ^ w[j*4 + 1];
            assign w[j*4 + 3] = w[j*4 - 1] ^ w[j*4 + 2];
        end
    endgenerate

   
    // 4. Output Multiplexer
    // Select the correct 128-bit key based on the current round number.
   
    assign round_key = {w[round*4], w[round*4+1], w[round*4+2], w[round*4+3]};

endmodule

