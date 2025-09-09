`timescale 1 ns / 10 ps

module MaxPoolMulti (
    clk,
    reset,
    apInput,
    apOutput
);

    parameter DATA_WIDTH = 16;
    parameter D = 6;
    parameter H = 28;
    parameter W = 28;

    input reset, clk;
    input [H*W*D*DATA_WIDTH-1:0] apInput;
    output reg [(H/2)*(W/2)*D*DATA_WIDTH-1:0] apOutput;

    reg     [        H*W*DATA_WIDTH-1:0] apInput_s;
    wire    [(H/2)*(W/2)*DATA_WIDTH-1:0] apOutput_s;
    integer                              counter;


    MaxPoolSingle #(
        .DATA_WIDTH(DATA_WIDTH),
        .InputH(H),
        .InputW(W)
    ) maxPool (
        .aPoolIn (apInput_s),
        .aPoolOut(apOutput_s)
    );

    always @(posedge clk or posedge reset) begin
        if (reset == 1'b1) begin
            counter = 0;
        end else if (counter < D) begin
            counter = counter + 1;
        end
    end

    always @(*) begin
        apInput_s = apInput[counter*H*W*DATA_WIDTH+:H*W*DATA_WIDTH];
        apOutput[counter*(H/2)*(W/2)*DATA_WIDTH+:(H/2)*(W/2)*DATA_WIDTH] = apOutput_s;
    end

endmodule
