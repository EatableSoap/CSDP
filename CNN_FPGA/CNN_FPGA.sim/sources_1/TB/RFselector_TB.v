// CNN_FGPA\CNN_FPGA.sim\sources_1\imports\Integration first part\RFselector.v
`timescale 100 ns / 10 ps

module RFselector_TB ();

parameter DATA_WIDTH = 16;
parameter D = 1; //Depth of the filter
parameter H = 32; //Height of the image
parameter W = 32; //Width of the image
parameter F = 5; //Size of the filter

localparam field_size = (W - F + 1) / 2 * D * F * F * DATA_WIDTH;
reg [D*H*W*DATA_WIDTH-1:0] image;
reg [5:0] rowNumber;
reg [5:0] column;
wire [field_size-1:0] receptiveField;
reg [field_size-1:0] expect_field;

RFselector #(
    .DATA_WIDTH(DATA_WIDTH),
    .D(D),
    .H(H),
    .W(W),
    .F(F)
)
UUT 
(
    .image(image),
    .rowNumber(rowNumber),
    .column(column),
    .receptiveField(receptiveField)
);

task initialize_image;
integer d, h, w;
integer pixel_index;
begin
    image = 0;
    pixel_index = 0;
    for (d = 0; d < 1; d = d + 1) begin
        for (h = 0; h < 32; h = h + 1) begin
            for (w = 0; w < 32; w = w + 1) begin
                image[pixel_index*16 +: 16] = pixel_index[16-1:0];
                pixel_index = pixel_index + 1;
            end
        end
    end
end
endtask

task calculate_expected_output_row10_col0;
integer c, k, i, f_w;
integer rf_index;
integer base_image_index;
integer current_image_index;
begin
    expect_field = 0;
    rf_index = 0;
    for (c = 0; c < (32 - 5 + 1) / 2; c = c + 1) begin
            for (k = 0; k < 1; k = k + 1) begin
                for (i = 0; i < 5; i = i + 1) begin
                    base_image_index = rowNumber * 32 + c + i * 32; // 320 + c + i * 32
                    for (f_w = 0; f_w < 5; f_w = f_w + 1) begin
                        current_image_index = base_image_index + f_w;
                        expect_field[rf_index*16 +: 16] = image[current_image_index*16 +: 16];
                        rf_index = rf_index + 1;
                    end
                end
            end
        end
    end
endtask

task run_test_case;
    input [5:0] test_rowNumber;
    input [5:0] test_column;
    integer i;
    reg match;
begin
    rowNumber = test_rowNumber;
    column = test_column;
        
    #1
    match = 1;
    if (receptiveField !== expect_field) begin
        match = 0;
        $display("Mismatch detected!");
        $display("First few pixels of output:");
        for(i = 0; i < 10; i = i + 1) begin
            $display("  Pixel[%d] = %h", i, receptiveField[i*16+:16]);
        end
        $display("First few pixels of expected:");
        for(i = 0; i < 10; i = i + 1) begin
            $display("  Pixel[%d] = %h", i, expect_field[i*16+:16]);
        end
    end

    if (match) begin
        $display("PASS: Output matches expected for rowNumber=%d, column=%d.", test_rowNumber, test_column);
    end else begin
        $display("FAIL: Output differs from expected for rowNumber=%d, column=%d.", test_rowNumber, test_column);
    end
end
endtask

initial begin
    initialize_image();
    rowNumber = 6'd10;
    column = 6'd0;
    calculate_expected_output_row10_col0();

    run_test_case(6'd10, 6'd0);

    $stop;
end

endmodule