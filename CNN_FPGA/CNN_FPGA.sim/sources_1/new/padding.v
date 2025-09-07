`timescale 1ns / 1ps

module padding (
    clk,
    rst,
    image_in,
    image_out
);
    parameter DATA_WIDTH = 16;
    parameter D = 1;
    parameter H = 32;
    parameter W = 32;
    parameter P = 0;

    input clk, rst;
    input [0:D*H*W*DATA_WIDTH-1] image_in;
    output reg [0:D*(H+2*P)*(W+2*P)*DATA_WIDTH-1] image_out;

    integer i, j, d;

    function integer output_index;
        input integer d, i, j;
        begin
            output_index = (d * (H+2*P) * (W+2*P) + i * (W + 2*P) + j) * DATA_WIDTH;
        end
    endfunction

    function integer input_index;
        input integer d, i, j;
        begin
            input_index = (d * H * W + i * W + j) * DATA_WIDTH;
        end
    endfunction

    always @(posedge clk) begin
        // Copy input image to the center of the output image
        for (d = 0; d < D; d = d + 1) begin
            for (i = 0; i < H + 2 * P; i = i + 1) begin
                for (j = 0; j < W + 2 * P; j = j + 1) begin
                    if(i < P || i >= H + P || j < P || j >= W + P) begin
                        image_out[output_index(d, i, j)+:DATA_WIDTH] <= 0;
                    end
                    else begin
                        image_out[output_index(d, i, j)+:DATA_WIDTH] <=
                        image_in[input_index(d, i-P, j-P)+:DATA_WIDTH];
                    end
                end
            end
        end
    end

endmodule
