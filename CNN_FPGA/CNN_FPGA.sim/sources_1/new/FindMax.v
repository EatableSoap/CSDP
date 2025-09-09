module FindMax (
    n,
    max,
    valid
);
    parameter DATA_WIDTH = 320;  // 10个 float32 (10*32=320)

    input valid;
    input [DATA_WIDTH-1:0] n;
    output [3:0] max;
    integer fd, code;

    wire [35:0] n1, n2, n3, n4, n5, n6, n7, n8, n9, n10;

    assign n1  = {4'b1001, n[31:0]};
    assign n2  = {4'b1000, n[63:32]};
    assign n3  = {4'b0111, n[95:64]};
    assign n4  = {4'b0110, n[127:96]};
    assign n5  = {4'b0101, n[159:128]};
    assign n6  = {4'b0100, n[191:160]};
    assign n7  = {4'b0011, n[223:192]};
    assign n8  = {4'b0010, n[255:224]};
    assign n9  = {4'b0001, n[287:256]};
    assign n10 = {4'b0000, n[319:288]};

    // pairwise compare wires
    wire [35:0] max12, max34, max56, max78, max90;
    wire [35:0] max14, max58;
    wire [35:0] max18;
    wire [35:0] max10;

    // 比较器输出
    wire gt12, eq12, gt34, eq34, gt56, eq56, gt78, eq78, gt90, eq90;
    wire gt14, eq14, gt58, eq58, gt18, eq18, gt100, eq100;

    // 实例化比较器
    fp32_cmp cmp12 (
        .a     (n1[31:0]),
        .b     (n2[31:0]),
        .a_gt_b(gt12),
        .a_eq_b(eq12)
    );
    assign max12 = gt12 ? n1 : n2;

    fp32_cmp cmp34 (
        .a     (n3[31:0]),
        .b     (n4[31:0]),
        .a_gt_b(gt34),
        .a_eq_b(eq34)
    );
    assign max34 = gt34 ? n3 : n4;

    fp32_cmp cmp56 (
        .a     (n5[31:0]),
        .b     (n6[31:0]),
        .a_gt_b(gt56),
        .a_eq_b(eq56)
    );
    assign max56 = gt56 ? n5 : n6;

    fp32_cmp cmp78 (
        .a     (n7[31:0]),
        .b     (n8[31:0]),
        .a_gt_b(gt78),
        .a_eq_b(eq78)
    );
    assign max78 = gt78 ? n7 : n8;

    fp32_cmp cmp90 (
        .a     (n9[31:0]),
        .b     (n10[31:0]),
        .a_gt_b(gt90),
        .a_eq_b(eq90)
    );
    assign max90 = gt90 ? n9 : n10;

    fp32_cmp cmp14 (
        .a     (max12[31:0]),
        .b     (max34[31:0]),
        .a_gt_b(gt14),
        .a_eq_b(eq14)
    );
    assign max14 = gt14 ? max12 : max34;

    fp32_cmp cmp58 (
        .a     (max56[31:0]),
        .b     (max78[31:0]),
        .a_gt_b(gt58),
        .a_eq_b(eq58)
    );
    assign max58 = gt58 ? max56 : max78;

    fp32_cmp cmp18 (
        .a     (max14[31:0]),
        .b     (max58[31:0]),
        .a_gt_b(gt18),
        .a_eq_b(eq18)
    );
    assign max18 = gt18 ? max14 : max58;

    fp32_cmp cmp100 (
        .a     (max18[31:0]),
        .b     (max90[31:0]),
        .a_gt_b(gt100),
        .a_eq_b(eq100)
    );
    assign max10 = gt100 ? max18 : max90;

    assign max   = max10[35:32];

    initial begin
        fd = $fopen("D:/Material/CSDP/Data/test_output.txt", "w");
    end

    always @(posedge valid) begin
        $fwrite(fd, "%d\n", max);
        $display("Cur Output is : %d", max);
    end
endmodule
