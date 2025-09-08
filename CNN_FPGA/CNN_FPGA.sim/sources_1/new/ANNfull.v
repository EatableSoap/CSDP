module ANNfull (
    clk,
    reset,
    input_ANN,
    output_ANN
);

    parameter DATA_WIDTH = 32;
    parameter INPUT_NODES_L1 = 288;
    parameter INPUT_NODES_L2 = 120;
    parameter INPUT_NODES_L3 = 120;
    parameter INPUT_NODES_L4 = 84;
    parameter OUTPUT_NODES = 10;

    input clk, reset;
    input [DATA_WIDTH*INPUT_NODES_L1-1:0] input_ANN;
    output [3:0] output_ANN;

    // shared address used to step through inputs/activation indices
    reg [10:0] address;

    // control signals
    reg enRelu, rstLayer;
    reg rstRelu1, rstRelu2, rstRelu3;
    reg valid;
    reg reW1, reW2, reW3, reW4;  // weightMemory enable for each weight block

    // layer wires
    wire [DATA_WIDTH*INPUT_NODES_L2-1:0] output_L1;
    wire [DATA_WIDTH*INPUT_NODES_L2-1:0] output_L1_relu;

    wire [DATA_WIDTH*INPUT_NODES_L3-1:0] output_L2;
    wire [DATA_WIDTH*INPUT_NODES_L3-1:0] output_L2_relu;

    wire [DATA_WIDTH*INPUT_NODES_L4-1:0] output_L3;
    wire [DATA_WIDTH*INPUT_NODES_L4-1:0] output_L3_relu;

    wire [  DATA_WIDTH*OUTPUT_NODES-1:0] output_L4;

    wire [DATA_WIDTH*INPUT_NODES_L2-1:0] WL1;
    wire [DATA_WIDTH*INPUT_NODES_L3-1:0] WL2;
    wire [DATA_WIDTH*INPUT_NODES_L4-1:0] WL3;
    wire [  DATA_WIDTH*OUTPUT_NODES-1:0] WL4;

    integer state, next_state;

    localparam S_IDLE    = 0,
               S_L1_RST  = 1,
               S_L1_ACC  = 2,
               S_L1_RELU = 3,
               S_L2_RST  = 4,
               S_L2_ACC  = 5,
               S_L2_RELU = 6,
               S_L3_RST  = 7,
               S_L3_ACC  = 8,
               S_L3_RELU = 9,
               S_L4_RST  = 10,
               S_L4_ACC  = 11,
               S_L4_RELU = 12,
               S_DONE    = 13;

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L1),
        .OUTPUT_NODES(INPUT_NODES_L2),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc1_hex.txt")
    ) W1 (
        .clk    (clk),
        .en     (reW1),
        .address(address),
        .weights(WL1)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L2),
        .OUTPUT_NODES(INPUT_NODES_L3),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc2_hex.txt")
    ) W2 (
        .clk    (clk),
        .en     (reW2),
        .address(address),
        .weights(WL2)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L3),
        .OUTPUT_NODES(INPUT_NODES_L4),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc3_hex.txt")
    ) W3 (
        .clk    (clk),
        .en     (reW3),
        .address(address),
        .weights(WL3)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L4),
        .OUTPUT_NODES(OUTPUT_NODES),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc4_hex.txt")
    ) W4 (
        .clk    (clk),
        .en     (reW4),
        .address(address),
        .weights(WL4)
    );

    layer #(
        .INPUT_NODES (INPUT_NODES_L1),
        .OUTPUT_NODES(INPUT_NODES_L2)
    ) L1 (
        .clk      (clk),
        .reset    (rstLayer),
        .address  (address),
        .input_fc (input_ANN),
        .weights  (WL1),
        .output_fc(output_L1)
    );

    activationFunction #(
        .OUTPUT_NODES(INPUT_NODES_L2)
    ) relu_1 (
        .clk      (clk),
        .reset    (rstRelu1),
        .en       (enRelu),
        .input_fc (output_L1),
        .output_fc(output_L1_relu)
    );

    layer #(
        .INPUT_NODES (INPUT_NODES_L2),
        .OUTPUT_NODES(INPUT_NODES_L3)
    ) L2 (
        .clk      (clk),
        .reset    (rstLayer),
        .address  (address),
        .input_fc (output_L1_relu),
        .weights  (WL2),
        .output_fc(output_L2)
    );

    activationFunction #(
        .OUTPUT_NODES(INPUT_NODES_L3)
    ) relu_2 (
        .clk      (clk),
        .reset    (rstRelu2),
        .en       (enRelu),
        .input_fc (output_L2),
        .output_fc(output_L2_relu)
    );

    layer #(
        .INPUT_NODES (INPUT_NODES_L3),
        .OUTPUT_NODES(INPUT_NODES_L4)
    ) L3 (
        .clk      (clk),
        .reset    (rstLayer),
        .address  (address),
        .input_fc (output_L2_relu),
        .weights  (WL3),
        .output_fc(output_L3)
    );

    activationFunction #(
        .OUTPUT_NODES(INPUT_NODES_L4)
    ) relu_3 (
        .clk      (clk),
        .reset    (rstRelu3),
        .en       (enRelu),
        .input_fc (output_L3),
        .output_fc(output_L3_relu)
    );

    layer #(
        .INPUT_NODES (INPUT_NODES_L4),
        .OUTPUT_NODES(OUTPUT_NODES)
    ) L4 (
        .clk      (clk),
        .reset    (rstLayer),
        .address  (address),
        .input_fc (output_L3_relu),
        .weights  (WL4),
        .output_fc(output_L4)
    );

    FindMax findmax1 (
        .n    (output_L4),
        .max  (output_ANN),
        .valid(valid)
    );

    always @(*) begin
        // defaults
        next_state = state;
        reW1 = 0;
        reW2 = 0;
        reW3 = 0;
        reW4 = 0;
        enRelu = 1'b0;
        // rstLayer / rstRelu are derived in sequential block for clear one-cycle pulses
        valid = 1'b0;

        case (state)
            S_IDLE: next_state = S_L1_RST;

            // --- L1 ---
            S_L1_RST: begin
                // assert W1 read enable and pulse layer reset (handled in seq block)
                reW1 = 1'b1;
                next_state = S_L1_ACC;
            end

            S_L1_ACC: begin
                reW1 = 1'b1;
                // count from 0 .. INPUT_NODES_L1-1
                if (address == INPUT_NODES_L1 + 1) begin
                    next_state = S_L1_RELU;
                    address = -1;  // reset address for next layer
                end
            end

            S_L1_RELU: begin
                // stop changing W1 (reW1=0), pulse relu reset and enable relu
                enRelu = 1'b1;
                // activation outputs have length INPUT_NODES_L2, so wait until address reaches that end
                if (address == 0) next_state = S_L2_RST;
            end

            // --- L2 ---
            S_L2_RST: begin
                reW2 = 1'b1;
                next_state = S_L2_ACC;
            end

            S_L2_ACC: begin
                reW2 = 1'b1;
                if (address == INPUT_NODES_L2 + 1) begin
                    next_state = S_L2_RELU;
                    address = -1;  // reset address for next layer
                end
            end

            S_L2_RELU: begin
                enRelu = 1'b1;
                if (address == 0) next_state = S_L3_RST;
            end

            // --- L3 ---
            S_L3_RST: begin
                reW3 = 1'b1;
                next_state = S_L3_ACC;
            end

            S_L3_ACC: begin
                reW3 = 1'b1;
                if (address == INPUT_NODES_L3 + 1) begin
                    next_state = S_L3_RELU;
                    address = -1;  // reset address for next layer
                end
            end

            S_L3_RELU: begin
                enRelu = 1'b1;
                if (address == 0) next_state = S_L4_RST;
            end

            // --- L4 ---
            S_L4_RST: begin
                reW4 = 1'b1;
                next_state = S_L4_ACC;
            end

            S_L4_ACC: begin
                reW4 = 1'b1;
                if (address == INPUT_NODES_L4 + 1) next_state = S_L4_RELU;
            end

            S_L4_RELU: begin
                // no relu on final layer
                next_state = S_DONE;
            end

            // --- DONE ---
            S_DONE: begin
                valid = 1'b1;
                // stay in DONE until reset; optionally could go back to IDLE
                next_state = S_DONE;
            end

            default: next_state = S_IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state = S_IDLE;
            address = -1;
            rstLayer = 1'b1;
            rstRelu1 = 1'b1;
            rstRelu2 = 1'b1;
            rstRelu3 = 1'b1;
            enRelu = 1'b0;
            valid = 1'b0;
        end else begin
            state = next_state;

            case (next_state)
                S_L1_RST, S_L2_RST, S_L3_RST, S_L4_RST: address = -1;
                S_L1_ACC, S_L2_ACC, S_L3_ACC, S_L4_ACC, S_L1_RELU, S_L2_RELU, S_L3_RELU:
                address = address + 1;
                default: address = 0;
            endcase

            rstLayer <= (next_state == S_L1_RST) ||
                        (next_state == S_L2_RST) ||
                        (next_state == S_L3_RST) ||
                        (next_state == S_L4_RST);

            rstRelu1 <= (next_state == S_L2_RELU);
            rstRelu2 <= (next_state == S_L3_RELU);
            rstRelu3 <= (next_state == S_L4_RELU);

            enRelu <= (next_state == S_L1_RELU) ||
                      (next_state == S_L2_RELU) ||
                      (next_state == S_L3_RELU);

            valid <= (next_state == S_DONE);
        end
    end

endmodule
