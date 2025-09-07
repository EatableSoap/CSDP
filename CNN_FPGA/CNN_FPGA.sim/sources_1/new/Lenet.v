module Lenet (
    clk,
    reset,
    CNNinput,
    Conv1F,
    Conv2F,
    Conv3F,
    LeNetoutput
);

    parameter DATA_WIDTH_1 = 16;
    parameter DATA_WIDTH_2 = 32;
    parameter ImgInW = 32;
    parameter ImgInH = 32;
    parameter DepthC1 = 6;
    parameter Conv1Kernel = 5;
    parameter DepthC2 = 16;
    parameter Conv2Kernel = 5;
    parameter DepthC3 = 32;
    parameter Conv3Kernel = 3;
    parameter MvgP3out = 3;

    integer counter;

    input clk, reset;
    input [ImgInW*ImgInH*DATA_WIDTH_1-1:0] CNNinput;  // lenet input
    input [Conv1Kernel*Conv1Kernel*DepthC1*DATA_WIDTH_1-1:0] Conv1F;  // Convolution1 weights
    input [DepthC2*Conv2Kernel*Conv2Kernel*DepthC1*DATA_WIDTH_1-1:0] Conv2F; // Convolution2 weights
    input [DepthC3*Conv3Kernel*Conv3Kernel*DepthC2*DATA_WIDTH_1-1:0] Conv3F;  // Convolution3 weights
    output [3:0] LeNetoutput;

    reg reset1, reset2;

    wire [MvgP3out*MvgP3out*DepthC3*DATA_WIDTH_1-1:0] CNNout;  // CNN output 5*5*32*16=12800
    wire [MvgP3out*MvgP3out*DepthC3*DATA_WIDTH_2-1:0] ANNin;  // ANN input 5*5*32*32=25600

    integrationConv C1 (
        .clk        (clk),
        .reset      (reset1),
        .CNNinput   (CNNinput),
        .Conv1F     (Conv1F),
        .Conv2F     (Conv2F),
        .Conv3F     (Conv3F),
        .iConvOutput(CNNout)
    );

    IEEE162IEEE32 #(
        .NODES(MvgP3out * MvgP3out * DepthC3)
    ) T1 (
        .clk      (clk),
        .reset    (reset),
        .input_fc (CNNout),
        .output_fc(ANNin)
    );

    ANNfull A1 (
        .clk       (clk),
        .reset     (reset2),
        .input_ANN (ANNin),
        .output_ANN(LeNetoutput)
    );

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            reset1  = 1'b1;
            reset2  = 1'b1;
            counter = 0;
        end else begin
            counter = counter + 1;
            if (counter < 7*1793+6*1024*6+12+16*32*29 + 6*2304 + 25 + 32*24*29 + 6*1152 + 30 + 15000) begin
                reset1 = 1'b0;
            end else begin
                reset2 = 1'b0;
            end
        end
    end
endmodule
