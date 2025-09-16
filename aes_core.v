`timescale 1ns/1ps

module aes_core (
    input                clk,
    input                rst,
    input                start,
    input        [127:0] plaintext,
    input        [127:0] key,
    output reg           done,
    output reg   [127:0] ciphertext
);

    // 1. State machine
    localparam IDLE       = 3'd0;
    localparam INIT       = 3'd1;
    localparam ROUND      = 3'd2;
    localparam LAST_ROUND = 3'd3;
    localparam FINISH     = 3'd4;

    reg [2:0] state, next_state;

    // 2. Datapath registers/wires
    reg  [127:0] state_reg;
    reg  [3:0]   round_counter;

    wire [127:0] round_key;
    wire [127:0] after_add_round_key;
    wire [127:0] after_sub_bytes;
    wire [127:0] after_shift_rows;
    wire [127:0] after_mix_columns;

    // 3. Component instantiation
    key_expansion key_exp_inst (
        .initial_key(key),
        .round(round_counter),
        .round_key(round_key)
    );

    mix_columns mix_col_inst (
        .in_state(after_shift_rows),
        .out_state(after_mix_columns)
    );

    // 4. Combinational datapath
    assign after_add_round_key = state_reg ^ round_key;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : S_BOX_INSTANCES
            sbox sbox_inst (
                .in_byte(state_reg[i*8 +: 8]),
                .out_byte(after_sub_bytes[i*8 +: 8])
            );
        end
    endgenerate

    assign after_shift_rows = {
        after_sub_bytes[103:96],  after_sub_bytes[79:72],  after_sub_bytes[55:48], after_sub_bytes[31:24],
        after_sub_bytes[111:104], after_sub_bytes[87:80],  after_sub_bytes[63:56], after_sub_bytes[7:0],
        after_sub_bytes[119:112], after_sub_bytes[95:88],  after_sub_bytes[39:32], after_sub_bytes[15:8],
        after_sub_bytes[127:120], after_sub_bytes[71:64],  after_sub_bytes[47:40], after_sub_bytes[23:16]
    };

    // 5. Sequential state and datapath update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            round_counter <= 4'd0;
            state_reg     <= 128'd0;
            done          <= 1'b0;
            ciphertext    <= 128'd0;
        end else begin
            // default done low; FINISH will assert one cycle
            done <= 1'b0;

            // register update: state and datapath/registers
            state <= next_state;

            case (state)
                IDLE: begin
                    // keep round_counter at 0 unless we start
                    round_counter <= 4'd0;
                    if (start) begin
                        state_reg <= plaintext;
                    end
                end

                INIT: begin
                    state_reg     <= after_add_round_key;
                    round_counter <= 4'd1; // first round index after initial addRoundKey
                end

                ROUND: begin
                    state_reg     <= after_mix_columns ^ round_key;
                    round_counter <= round_counter + 4'd1;
                end

                LAST_ROUND: begin
                    state_reg     <= after_shift_rows ^ round_key;
                    round_counter <= round_counter + 4'd1;
                end

                FINISH: begin
                    ciphertext <= state_reg;
                    done       <= 1'b1; // single-cycle done pulse
                    // leave round_counter as-is or clear on next IDLE
                end

                default: begin
                    state_reg <= state_reg;
                end
            endcase
        end
    end

    // 6. Combinational next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = INIT;
                else
                    next_state = IDLE;
            end

            INIT: begin
                next_state = ROUND;
            end

            ROUND: begin
                if (round_counter == 4'd9)
                    next_state = LAST_ROUND;
                else
                    next_state = ROUND;
            end

            LAST_ROUND: begin
                next_state = FINISH;
            end

            FINISH: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule