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

    reg                                     rstLayer;
    reg                                     rstRelu;
    reg                                     enRelu;
    reg                                     valid = 1'b0;

    reg     [                         10:0] address;

    wire    [DATA_WIDTH*INPUT_NODES_L2-1:0] output_L1;
    wire    [DATA_WIDTH*INPUT_NODES_L2-1:0] output_L1_relu;

    wire    [DATA_WIDTH*INPUT_NODES_L3-1:0] output_L2;
    wire    [DATA_WIDTH*INPUT_NODES_L3-1:0] output_L2_relu;

    wire    [DATA_WIDTH*INPUT_NODES_L4-1:0] output_L3;
    wire    [DATA_WIDTH*INPUT_NODES_L4-1:0] output_L3_relu;

    wire    [  DATA_WIDTH*OUTPUT_NODES-1:0] output_L4;

    wire    [DATA_WIDTH*INPUT_NODES_L2-1:0] WL1;
    wire    [DATA_WIDTH*INPUT_NODES_L3-1:0] WL2;
    wire    [DATA_WIDTH*INPUT_NODES_L4-1:0] WL3;
    wire    [  DATA_WIDTH*OUTPUT_NODES-1:0] WL4;

    integer                                 turn = 1;

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L1),
        .OUTPUT_NODES(INPUT_NODES_L2),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc1_hex.txt")
    ) W1 (
        .clk    (clk),
        .address(address),
        .weights(WL1)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L2),
        .OUTPUT_NODES(INPUT_NODES_L3),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc2_hex.txt")
    ) W2 (
        .clk    (clk),
        .address(address),
        .weights(WL2)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L3),
        .OUTPUT_NODES(INPUT_NODES_L4),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc3_hex.txt")
    ) W3 (
        .clk    (clk),
        .address(address),
        .weights(WL3)
    );

    weightMemory #(
        .INPUT_NODES(INPUT_NODES_L4),
        .OUTPUT_NODES(OUTPUT_NODES),
        .file("D:/Material/CSDP/Data/Weight/distilled/fc4_hex.txt")
    ) W4 (
        .clk    (clk),
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
        .reset    (rstRelu),
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
        .reset    (rstRelu),
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
        .reset    (rstRelu),
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


    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            rstRelu = 1'b1;
            rstLayer = 1'b1;
            address = -1;
            enRelu = 1'b0;
            valid = 1'b0;
        end else begin
            rstRelu  = 1'b0;
            rstLayer = 1'b0;
            if (turn == 1 && address == INPUT_NODES_L1 + 1) begin
                address = address + 1;
                enRelu  = 1'b1;
                $display("Cur Input is : %h", input_ANN);
                $display("Cur Output is : %h", output_L1);
            end else if (turn == 1 && address == INPUT_NODES_L1 + 2) begin
                address = -1;
                enRelu = 1'b0;
                rstLayer = 1'b1;
                turn = turn + 1;
            end else if (turn == 2 && address == INPUT_NODES_L2 + 1) begin
                address = address + 1;
                enRelu  = 1'b1;
                $display("Cur Input is : %h", output_L1_relu);
                $display("Cur Output is : %h", output_L2);
            end else if (turn == 2 && address == INPUT_NODES_L2 + 2) begin
                address = -1;
                enRelu = 1'b0;
                rstLayer = 1'b1;
                turn = turn + 1;
            end else if (turn == 3 && address == INPUT_NODES_L3 + 1) begin
                address = address + 1;
                enRelu  = 1'b1;
                $display("Cur Input is : %h", output_L2_relu);
                $display("Cur Output is : %h", output_L3);
            end else if (turn == 3 && address == INPUT_NODES_L3 + 2) begin
                address = -1;
                enRelu = 1'b0;
                rstLayer = 1'b1;
                turn = turn + 1;
            end else if (turn == 4 && address == INPUT_NODES_L4 + 1) begin
                rstRelu = 1'b1;
                rstLayer = 1'b1;
                address = -1;
                enRelu = 1'b0;
                turn = 1;
                valid = 1'b1;
                $display("Cur Input is : %h", output_L3_relu);
                $display("Cur Output is : %h", output_L4);
            end else begin
                address = address + 1;
            end
        end
    end

endmodule
