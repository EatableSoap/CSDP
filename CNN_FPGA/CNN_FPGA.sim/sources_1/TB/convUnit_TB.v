// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\convUnit.v
`timescale 100 ns / 10 ps

module convUnit_TB ();

parameter DATA_WIDTH = 16;
parameter D = 1;
parameter F = 5;

// tag: convUnit.v is [0:n-1]
reg clk, reset;
reg [D*F*F*DATA_WIDTH-1:0] image, filter;
wire [DATA_WIDTH-1:0] result;

localparam PERIOD = 100;

always
	#(PERIOD/2) clk = ~clk;


convUnit 
#(
	.DATA_WIDTH(16),
	.D(1),
	.F(5)
)
UUT
(
	.clk(clk),
	.reset(reset),
	.image(image),
	.filter(filter),
	.result(result)
);

initial begin
	#0
	clk = 1'b0;
	reset = 1;
    
    // input = 1*5*5*16 = 400 bit
	image =  400'h2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222;
	filter = 400'h2200220022002200220022002200220022002200220022002200220022002200220022002200220022002200220022002200;
	
	#PERIOD
	reset = 0;
	
	#(27*PERIOD)
	// $displayh(result);
    $display("Result (hex): %h", result);
	$stop;
end

endmodule