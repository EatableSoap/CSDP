module fp16_cmp (
    input  [15:0] a,
    input  [15:0] b,
    output        a_gt_b,  // a > b (数值意义)
    output        a_eq_b   // a == b (数值意义, treat +0 and -0 equal)
);
    // bit fields
    wire       sa = a[15];
    wire       sb = b[15];
    wire [4:0] ea = a[14:10];
    wire [4:0] eb = b[14:10];
    wire [9:0] fa = a[9:0];
    wire [9:0] fb = b[9:0];

    // detect special
    wire       a_is_nan = (ea == 5'b11111) && (fa != 0);
    wire       b_is_nan = (eb == 5'b11111) && (fb != 0);
    wire       a_is_zero = (ea == 5'b00000) && (fa == 0);
    wire       b_is_zero = (eb == 5'b00000) && (fb == 0);

    // equality: treat numeric equality: either exact same bits OR both zeros
    assign a_eq_b = (a == b) || (a_is_zero && b_is_zero);

    // Decide ordering (we choose policy: NaN is treated as "less than" any non-NaN;
    // if both are NaN, treat them equal and a_gt_b = 0).
    // (If you prefer NaN to propagate as max, change the NaN handling.)
    reg gt;
    always @(*) begin
        // default
        gt = 1'b0;
        if (a_is_nan && b_is_nan) begin
            gt = 1'b0;  // equal-ish, not greater
        end else if (a_is_nan && !b_is_nan) begin
            gt = 1'b0;  // NaN considered smallest
        end else if (!a_is_nan && b_is_nan) begin
            gt = 1'b1;
        end else if (a_eq_b) begin
            gt = 1'b0;  // not greater if equal
        end else begin
            // normal numeric compare
            if (sa != sb) begin
                // different signs: positive > negative
                gt = (sa == 1'b0) ? 1'b1 : 1'b0;
            end else if (sa == 1'b0) begin
                // both positive: bigger exponent => bigger number
                if (ea != eb) gt = (ea > eb);
                else gt = (fa > fb);
            end else begin
                // both negative: more negative magnitude -> smaller.
                // so a > b iff magnitude(a) < magnitude(b)
                if (ea != eb) gt = (ea < eb);
                else gt = (fa < fb);
            end
        end
    end

    assign a_gt_b = gt;
endmodule

module fp32_cmp (
    input  [31:0] a,
    input  [31:0] b,
    output        a_gt_b,  // a > b
    output        a_eq_b   // a == b (treat +0 == -0)
);
    // bit fields
    wire        sa = a[31];
    wire        sb = b[31];
    wire [ 7:0] ea = a[30:23];
    wire [ 7:0] eb = b[30:23];
    wire [22:0] fa = a[22:0];
    wire [22:0] fb = b[22:0];

    // detect special
    wire        a_is_nan = (ea == 8'hFF) && (fa != 0);
    wire        b_is_nan = (eb == 8'hFF) && (fb != 0);
    wire        a_is_zero = (ea == 8'h00) && (fa == 0);
    wire        b_is_zero = (eb == 8'h00) && (fb == 0);

    // equality: treat numeric equality (including +0 == -0)
    assign a_eq_b = (a == b) || (a_is_zero && b_is_zero);

    // greater-than flag
    reg gt;
    always @(*) begin
        gt = 1'b0;
        if (a_is_nan && b_is_nan) begin
            gt = 1'b0;
        end else if (a_is_nan && !b_is_nan) begin
            gt = 1'b0;  // NaN considered smallest
        end else if (!a_is_nan && b_is_nan) begin
            gt = 1'b1;
        end else if (a_eq_b) begin
            gt = 1'b0;
        end else begin
            // numeric compare
            if (sa != sb) begin
                gt = (sa == 1'b0) ? 1'b1 : 1'b0;  // positive > negative
            end else if (sa == 1'b0) begin
                // both positive
                if (ea != eb) gt = (ea > eb);
                else gt = (fa > fb);
            end else begin
                // both negative -> reverse
                if (ea != eb) gt = (ea < eb);
                else gt = (fa < fb);
            end
        end
    end

    assign a_gt_b = gt;
endmodule

// 4-input max using the comparator
module max (
    input  [15:0] n1,
    input  [15:0] n2,
    input  [15:0] n3,
    input  [15:0] n4,
    output [15:0] max
);

    parameter DATA_WIDTH = 16;
    wire gt12, eq12;
    wire gt34, eq34;
    wire [15:0] max12;
    wire [15:0] max34;
    wire gt_final, eq_final;

    fp16_cmp cmp12 (
        .a     (n1),
        .b     (n2),
        .a_gt_b(gt12),
        .a_eq_b(eq12)
    );
    assign max12 = gt12 ? n1 : n2;  // if equal, picks n2 (arbitrary, fine)

    fp16_cmp cmp34 (
        .a     (n3),
        .b     (n4),
        .a_gt_b(gt34),
        .a_eq_b(eq34)
    );
    assign max34 = gt34 ? n3 : n4;

    // compare max12 vs max34
    fp16_cmp cmpf (
        .a     (max12),
        .b     (max34),
        .a_gt_b(gt_final),
        .a_eq_b(eq_final)
    );
    assign max = gt_final ? max12 : max34;  // if equal picks max34 (arbitrary)
endmodule
