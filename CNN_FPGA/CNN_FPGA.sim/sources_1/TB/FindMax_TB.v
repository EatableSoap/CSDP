// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\FindMax.v
`timescale 1 ns / 1 ps

module FindMax_TB ();

parameter DATA_WIDTH = 320;

reg [DATA_WIDTH-1:0] n;
wire [3:0] max;

FindMax #(
    .DATA_WIDTH(DATA_WIDTH)
)
UUT
(
    .n(n),
    .max(max)
);

initial begin
#0
// input data = 320 bit
n = 320'hbe808ea3be799d503e06b8ee3c07c890be9d4b983e014309bdb708393e29a92a3d61ac73bd7a5b46;

#10
// $display("Output Max Index: %0d (Expected: %0d)", max, expected_index);
if (max == 4'd7) begin
    $display("correct\n");
end else begin
    $display("error\n");
end
    
$stop;
end

endmodule