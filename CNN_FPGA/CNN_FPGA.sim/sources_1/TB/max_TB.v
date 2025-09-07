// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\max.v
// `timescale 100 ns / 10 ps

module max_TB ();

// parameter DATA_WIDTH = 16;

reg [16-1:0] n1, n2, n3, n4;
wire [16-1:0] max;

initial begin
#0
n1 = 16'h1000;
n2 = 16'hCCCC;
n3 = 16'hCCCC;
n4 = 16'h3000;

#10
if (max === 16'hCCCC) begin
    $display("PASS\n");
end else begin
    $display("FAIL\n");
end
$stop;
end

max UUT (
    .n1(n1),
    .n2(n2),
    .n3(n3),
    .n4(n4),
    .max(max)
);

endmodule