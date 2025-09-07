// CNN_FGPA\CNN_FPGA.sim\sources_1\new\padding.v
`timescale 1 ns / 1 ps

module padding_TB ();

    parameter DATA_WIDTH = 16;
    parameter D = 1;
    parameter H = 10;
    parameter W = 10;
    parameter P = 2;

    reg clk, reset;
    reg [0:D*H*W*DATA_WIDTH-1] image_in;
    wire [0:D*(H+P*2)*(W+P*2)*DATA_WIDTH-1] image_out;

    localparam PERIOD = 100;

    always #(PERIOD / 2) clk = ~clk;

    padding #(
        .DATA_WIDTH(DATA_WIDTH),
        .D(D),
        .H(H),
        .W(W),
        .P(P)
    ) padUnit (
        .clk      (clk),
        .rst      (reset),
        .image_in (image_in),
        .image_out(image_out)
    );


    initial begin
        #0 clk = 1'b0;
        // image_in = 1*10*10*16 = 1600 bit
        image_in =  1600'h4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444;
        reset = 1'b1;

        // input: filled with 4
        // expect output: 400

        // #(5*PERIOD) reset = 0;

        #(PERIOD*2)
        // $displayh(image_out);
        $display(
            "Result (hex): %h", image_out
        );
        $stop;
    end



endmodule
