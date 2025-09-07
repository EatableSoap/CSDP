// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\UsingTheRelu16.v
`timescale 1 ns / 10 ps

module UsingTheRelu16_TB ();

parameter DATA_WIDTH = 16;
parameter OUTPUT_NODES = 32;

reg clk, reset, en;
reg [DATA_WIDTH*OUTPUT_NODES-1:0]input_fc;
wire [DATA_WIDTH*OUTPUT_NODES-1:0]output_fc;

localparam PERIOD = 100;

always
	#(PERIOD/2) clk = ~clk;

UsingTheRelu16 #(
    .DATA_WIDTH(DATA_WIDTH),
    .OUTPUT_NODES(OUTPUT_NODES)
)
UUT
(
	.clk(clk),
	.reset(reset),	
    .en(en),
    .input_fc(input_fc),
    .output_fc(output_fc)
);

initial begin
	#0
	clk = 1'b1;
	reset = 1'b1;
    en=1'b0;
    // input = 16*32 = 512 bit
    // test: input_fc = {7FFF,8000,0000,FFFF,0001,C000}
    //      expect_fc = {7FFF,0000,0000,0000,0001,0000}
	input_fc = 512'h7FFF_8000_0000_FFFF_0001_C000_00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

	#(PERIOD/2)
	reset = 1'b0;	
	en=1'b1;

	#800
	if(output_fc == 512'h7FFF_0000_0000_0000_0001_000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)begin 
	 $display("Result is right");	  
	end
	else begin 
	 $display("Result is Wrong");	 
	end	 
	$stop;
end

endmodule