`timescale 1ns / 1ps

module fp16_max_TB ();

    // 输入信号
    reg [15:0] a, b, c, d;
    wire [15:0] max_out;

    // 单个比较器测试
    wire gt, eq;
    fp16_cmp cmp_inst (
        .a     (a),
        .b     (b),
        .a_gt_b(gt),
        .a_eq_b(eq)
    );

    // 四输入最大值测试
    max uut (
        .n1     (a),
        .n2     (b),
        .n3     (c),
        .n4     (d),
        .max_out(max_out)
    );

    // 任务：打印浮点数（以 16 进制显示）
    task show_cmp;
        input [15:0] x;
        input [15:0] y;
        begin
            $display("Compare a=0x%h, b=0x%h => gt=%0d, eq=%0d", x, y, gt, eq);
        end
    endtask

    task show_max;
        input [15:0] x1, x2, x3, x4;
        begin
            $display("Max(0x%h,0x%h,0x%h,0x%h) = 0x%h", x1, x2, x3, x4, max_out);
        end
    endtask

    initial begin
        $display("=== fp16 comparator & max testbench ===");

        // 测试 1: 正数比较
        a = 16'h3C00;  // +1.0
        b = 16'h4000;  // +2.0
        #1 show_cmp(a, b);

        // 测试 2: 负数比较
        a = 16'hC000;  // -2.0
        b = 16'hBC00;  // -1.0
        #1 show_cmp(a, b);

        // 测试 3: 正零 vs 负零
        a = 16'h0000;  // +0.0
        b = 16'h8000;  // -0.0
        #1 show_cmp(a, b);

        // 测试 4: 正数 vs 负数
        a = 16'h3C00;  // +1.0
        b = 16'hBC00;  // -1.0
        #1 show_cmp(a, b);

        // 测试 5: Infinity vs finite
        a = 16'h7C00;  // +inf
        b = 16'h4000;  // +2.0
        #1 show_cmp(a, b);

        // 测试 6: NaN vs finite
        a = 16'h7E00;  // qNaN
        b = 16'h3C00;  // +1.0
        #1 show_cmp(a, b);

        // 测试 7: subnormal vs normal
        a = 16'h0001;  // 最小正次正规数
        b = 16'h1400;  // 正常小数 ~ 2^-14
        #1 show_cmp(a, b);

        // ===== 四输入 max 测试 =====
        a = 16'h3C00;  // +1.0
        b = 16'h4000;  // +2.0
        c = 16'hC000;  // -2.0
        d = 16'h7C00;  // +inf
        #1 show_max(a, b, c, d);

        a = 16'h3C00;  // +1.0
        b = 16'hBC00;  // -1.0
        c = 16'h7E00;  // NaN
        d = 16'h3400;  // 0.25
        #1 show_max(a, b, c, d);

        $finish;
    end

endmodule
