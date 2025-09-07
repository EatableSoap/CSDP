module integrationConv (
    clk,
    reset,
    CNNinput,
    Conv1F,
    Conv2F,
    Conv3F,
    iConvOutput
);

    parameter DATA_WIDTH = 16;
    parameter ImgInW = 32;
    parameter ImgInH = 32;
    parameter DepthC1 = 6;
    parameter Conv1Out = 32;
    parameter Conv1Kernel = 5;
    parameter MvgP1out = 16;
    parameter DepthC2 = 16;
    parameter Conv2Out = 12;
    parameter Conv2Kernel = 5;
    parameter MvgP2out = 6;
    parameter DepthC3 = 32;
    parameter Conv3Out = 6;
    parameter Conv3Kernel = 3;
    parameter MvgP3out = 3;

    integer counter;

    input clk, reset;
    input [ImgInW*ImgInH*DATA_WIDTH-1:0] CNNinput;
    input [1*Conv1Kernel*Conv1Kernel*DepthC1*DATA_WIDTH-1:0] Conv1F;
    input [DepthC1*Conv2Kernel*Conv2Kernel*DepthC2*DATA_WIDTH-1:0] Conv2F;
    input [DepthC2*Conv3Kernel*Conv3Kernel*DepthC3*DATA_WIDTH-1:0] Conv3F;
    output [MvgP3out*MvgP3out*DepthC3*DATA_WIDTH-1:0] iConvOutput;

    reg C1rst, C2rst, C3rst, MP1rst, MP2rst, MP3rst, Relu1Reset, Relu2Reset, Relu3Reset, enRelu;
    //wire Tanh1Flag,Tanh2Flag,Tanh3Flag;

    wire [Conv1Out*Conv1Out*DepthC1*DATA_WIDTH-1:0] C1out;
    wire [Conv1Out*Conv1Out*DepthC1*DATA_WIDTH-1:0] C1outRelu;

    wire [MvgP1out*MvgP1out*DepthC1*DATA_WIDTH-1:0] MP1out;

    wire [Conv2Out*Conv2Out*DepthC2*DATA_WIDTH-1:0] C2out;
    wire [Conv2Out*Conv2Out*DepthC2*DATA_WIDTH-1:0] C2outRelu;

    wire [MvgP2out*MvgP2out*DepthC2*DATA_WIDTH-1:0] MP2out;

    wire [Conv3Out*Conv3Out*DepthC3*DATA_WIDTH-1:0] C3out;
    wire [Conv3Out*Conv3Out*DepthC3*DATA_WIDTH-1:0] C3outRelu;

    wire [MvgP3out*MvgP3out*DepthC3*DATA_WIDTH-1:0] MP3out;

    convLayerMulti C1 (
        .clk       (clk),
        .reset     (reset),
        .image     (CNNinput),
        .filters   (Conv1F),
        .outputConv(C1out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv1Out * Conv1Out * DepthC1)
    ) relu_1 (
        .clk      (clk),
        .reset    (Relu1Reset),
        .en       (enRelu),
        .input_fc (C1out),
        .output_fc(C1outRelu)
    );

    MaxPoolMulti #(
        .D(6),
        .H(32),
        .W(32)
    ) MP1 (
        .clk     (clk),
        .reset   (MP1rst),
        .apInput (C1outRelu),
        .apOutput(MP1out)
    );

    convLayerMulti #(
        .DATA_WIDTH(16),
        .D(6),
        .H(16),
        .W(16),
        .F(5),
        .K(16),
        .P(0)
    ) C2 (
        .clk       (clk),
        .reset     (C2rst),
        .image     (MP1out),
        .filters   (Conv2F),
        .outputConv(C2out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv2Out * Conv2Out * DepthC2)
    ) relu_2 (
        .clk      (clk),
        .reset    (Relu2Reset),
        .en       (enRelu),
        .input_fc (C2out),
        .output_fc(C2outRelu)
    );

    MaxPoolMulti #(
        .D(16),
        .H(12),
        .W(12)
    ) MP2 (
        .clk     (clk),
        .reset   (MP2rst),
        .apInput (C2outRelu),
        .apOutput(MP2out)
    );

    convLayerMulti #(
        .DATA_WIDTH(16),
        .D(16),
        .H(6),
        .W(6),
        .F(3),
        .K(32),
        .P(1)
    ) C3 (
        .clk       (clk),
        .reset     (C3rst),
        .image     (MP2out),
        .filters   (Conv3F),
        .outputConv(C3out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv3Out * Conv3Out * DepthC3)
    ) relu_3 (
        .clk      (clk),
        .reset    (Relu3Reset),
        .en       (enRelu),
        .input_fc (C3out),
        .output_fc(C3outRelu)
    );

    MaxPoolMulti #(
        .D(32),
        .H(6),
        .W(6)
    ) MP3 (
        .clk     (clk),
        .reset   (MP3rst),
        .apInput (C3outRelu),
        .apOutput(iConvOutput)
    );

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            C1rst = 1'b1;
            C2rst = 1'b1;
            C3rst = 1'b1;
            MP1rst = 1'b1;
            MP2rst = 1'b1;
            MP3rst = 1'b1;
            Relu1Reset = 1'b1;
            Relu2Reset = 1'b1;
            Relu3Reset = 1'b1;
            enRelu = 1'b1;
            counter = 0;
            // There need to be modified according to the new structure
        end else begin
            counter = counter + 1;
            if (counter > 0 && counter < 7 * 1793) begin
                C1rst = 1'b0;
            end else if (counter > 7 * 1793 && counter < 7 * 1793 + 6 * 1024 * 6) begin
                Relu1Reset = 1'b0;
            end else if (counter > 7*1793+6*1024*6 && counter < 7*1793+6*1024*6+12) begin
                MP1rst = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12 && counter < 7*1793+6*1024*6+12+16*32*29) begin
                C2rst = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12+16*32*29 && counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304) begin
                Relu2Reset = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12+16*32*29 + 6*2304 && counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25) begin
                MP2rst = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 && counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29) begin
                C3rst = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29 && counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29 + 6*1152) begin
                Relu3Reset = 1'b0;
            end else if (counter > 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29 + 6*1152 && counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29 + 6*1152 + 30) begin
                MP3rst = 1'b0;
            end
        end
    end

endmodule
