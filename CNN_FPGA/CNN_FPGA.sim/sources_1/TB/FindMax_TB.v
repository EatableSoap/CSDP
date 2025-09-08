// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\FindMax.v
`timescale 1 ns / 1 ps

module FindMax_TB ();

    parameter DATA_WIDTH = 320;

    reg  [DATA_WIDTH-1:0] n;
    wire [           3:0] max;

    FindMax #(
        .DATA_WIDTH(DATA_WIDTH)
    ) UUT (
        .n  (n),
        .max(max)
    );

    initial begin
        #0
        // input data = 320 bit
        n = 320'hbed801a13ef081663bd00600beba9d873e13ae30be43c99940a3a7c13e0e3b14bea7c6cb3ee1a8a4;

        #10
        // $display("Output Max Index: %0d (Expected: %0d)", max, expected_index);
        if (max == 4'd6) begin
            $display("correct\n");
        end else begin
            $display("error\n");
        end

        $stop;
    end

endmodule
