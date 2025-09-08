module integrationConv (
    clk,
    reset,
    CNNinput,
    Conv1F,
    Conv2F,
    Conv3F,
    iConvOutput
);

    parameter DATA_WIDTH = 16;
    parameter ImgInW = 32;
    parameter ImgInH = 32;
    parameter DepthC1 = 6;
    parameter Conv1Out = 32;
    parameter Conv1Kernel = 5;
    parameter MvgP1out = 16;
    parameter DepthC2 = 16;
    parameter Conv2Out = 12;
    parameter Conv2Kernel = 5;
    parameter MvgP2out = 6;
    parameter DepthC3 = 32;
    parameter Conv3Out = 6;
    parameter Conv3Kernel = 3;
    parameter MvgP3out = 3;

    // === 状态定义 ===
    localparam S_IDLE   = 0,
             S_CONV1  = 1,
             S_RELU1  = 2,
             S_MP1    = 3,
             S_CONV2  = 4,
             S_RELU2  = 5,
             S_MP2    = 6,
             S_CONV3  = 7,
             S_RELU3  = 8,
             S_MP3    = 9,
             S_DONE   = 10;

    reg [3:0] state, next_state;
    reg [31:0] state_counter;

    input clk, reset;
    input [ImgInW*ImgInH*DATA_WIDTH-1:0] CNNinput;
    input [1*Conv1Kernel*Conv1Kernel*DepthC1*DATA_WIDTH-1:0] Conv1F;
    input [DepthC1*Conv2Kernel*Conv2Kernel*DepthC2*DATA_WIDTH-1:0] Conv2F;
    input [DepthC2*Conv3Kernel*Conv3Kernel*DepthC3*DATA_WIDTH-1:0] Conv3F;
    output [MvgP3out*MvgP3out*DepthC3*DATA_WIDTH-1:0] iConvOutput;

    reg C1rst, C2rst, C3rst, MP1rst, MP2rst, MP3rst, Relu1Reset, Relu2Reset, Relu3Reset, enRelu;
    //wire Tanh1Flag,Tanh2Flag,Tanh3Flag;

    wire [Conv1Out*Conv1Out*DepthC1*DATA_WIDTH-1:0] C1out;
    wire [Conv1Out*Conv1Out*DepthC1*DATA_WIDTH-1:0] C1outRelu;

    wire [MvgP1out*MvgP1out*DepthC1*DATA_WIDTH-1:0] MP1out;

    wire [Conv2Out*Conv2Out*DepthC2*DATA_WIDTH-1:0] C2out;
    wire [Conv2Out*Conv2Out*DepthC2*DATA_WIDTH-1:0] C2outRelu;

    wire [MvgP2out*MvgP2out*DepthC2*DATA_WIDTH-1:0] MP2out;

    wire [Conv3Out*Conv3Out*DepthC3*DATA_WIDTH-1:0] C3out;
    wire [Conv3Out*Conv3Out*DepthC3*DATA_WIDTH-1:0] C3outRelu;

    // ReLU/Pool 并行度
    localparam integer RELU_PAR = 1;
    localparam integer POOL_PAR = 1;

    // 这里 H_out/W_out 用的是对应层 conv 输出/池化输出）
    // 对卷积层 i：Hout_i = (Hi + 2*Pi) - Fi + 1
    function integer Hout;
        input integer H, P, F;
        begin
            Hout = (H + 2 * P) - F + 1;
        end
    endfunction
    function integer Wout;
        input integer W, P, F;
        begin
            Wout = (W + 2 * P) - F + 1;
        end
    endfunction

    // ---- 卷积层周期
    function integer CONV_LAYER_CYCLES;
        input integer D, H, P, F, K;
        integer H_out;
        begin
            H_out = Hout(H, P, F);
            CONV_LAYER_CYCLES = ((K + 1) / 2) * (2 * H_out * (D*F*F + 3) + 1); // ceil(K/2) = (K+1)/2 for int
        end
    endfunction

    // ---- ReLU 周期（逐元素 / 并行度）
    function integer RELU_CYCLES;
        input integer D, H, W;
        begin
            RELU_CYCLES = ((D * H * W) + (RELU_PAR - 1)) / RELU_PAR + 1;
        end
    endfunction

    // ---- MaxPool 周期（逐元素 / 并行度）
    function integer POOL_CYCLES;
        input integer D, H, W;
        begin
            POOL_CYCLES = ((D * H * W) + (POOL_PAR - 1)) / POOL_PAR + 1;
        end
    endfunction

    localparam integer C1_CYCLES = CONV_LAYER_CYCLES(  /*D=*/
        1,  /*H=*/ 32,  /*P=*/ (5 / 2),  /*F=*/ 5,  /*K=*/ 6
    );
    localparam integer RELU1_CYCLES = RELU_CYCLES(  /*D=*/
        6,  /*H=*/ Hout(32, (5 / 2), 5),  /*W=*/ Wout(32, (5 / 2), 5)
    );
    localparam integer MP1_CYCLES = POOL_CYCLES(  /*D=*/ 6,  /*H=*/ 16,  /*W=*/ 16);

    localparam integer C2_CYCLES = CONV_LAYER_CYCLES(  /*D=*/
        6,  /*H=*/ 16,  /*P=*/ 0,  /*F=*/ 5,  /*K=*/ 16
    );
    localparam integer RELU2_CYCLES = RELU_CYCLES(  /*D=*/
        16,  /*H=*/ Hout(16, 0, 5),  /*W=*/ Wout(16, 0, 5)
    );
    localparam integer MP2_CYCLES = POOL_CYCLES(  /*D=*/ 16,  /*H=*/ 6,  /*W=*/ 6);

    localparam integer C3_CYCLES = CONV_LAYER_CYCLES(  /*D=*/
        16,  /*H=*/ 6,  /*P=*/ 1,  /*F=*/ 3,  /*K=*/ 32
    );
    localparam integer RELU3_CYCLES = RELU_CYCLES(  /*D=*/
        32,  /*H=*/ Hout(6, 1, 3),  /*W=*/ Wout(6, 1, 3)
    );
    localparam integer MP3_CYCLES = POOL_CYCLES(  /*D=*/ 32,  /*H=*/ 3,  /*W=*/ 3);

    convLayerMulti #(
        .DATA_WIDTH(16),
        .D(1),
        .H(32),
        .W(32),
        .F(5),
        .K(6),
        .P(2)
    ) C1 (
        .clk       (clk),
        .reset     (reset),
        .image     (CNNinput),
        .filters   (Conv1F),
        .outputConv(C1out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv1Out * Conv1Out * DepthC1)
    ) relu_1 (
        .clk      (clk),
        .reset    (Relu1Reset),
        .en       (enRelu),
        .input_fc (C1out),
        .output_fc(C1outRelu)
    );

    MaxPoolMulti #(
        .D(6),
        .H(32),
        .W(32)
    ) MP1 (
        .clk     (clk),
        .reset   (MP1rst),
        .apInput (C1outRelu),
        .apOutput(MP1out)
    );

    convLayerMulti #(
        .DATA_WIDTH(16),
        .D(6),
        .H(16),
        .W(16),
        .F(5),
        .K(16),
        .P(0)
    ) C2 (
        .clk       (clk),
        .reset     (C2rst),
        .image     (MP1out),
        .filters   (Conv2F),
        .outputConv(C2out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv2Out * Conv2Out * DepthC2)
    ) relu_2 (
        .clk      (clk),
        .reset    (Relu2Reset),
        .en       (enRelu),
        .input_fc (C2out),
        .output_fc(C2outRelu)
    );

    MaxPoolMulti #(
        .D(16),
        .H(12),
        .W(12)
    ) MP2 (
        .clk     (clk),
        .reset   (MP2rst),
        .apInput (C2outRelu),
        .apOutput(MP2out)
    );

    convLayerMulti #(
        .DATA_WIDTH(16),
        .D(16),
        .H(6),
        .W(6),
        .F(3),
        .K(32),
        .P(1)
    ) C3 (
        .clk       (clk),
        .reset     (C3rst),
        .image     (MP2out),
        .filters   (Conv3F),
        .outputConv(C3out)
    );

    UsingTheRelu16 #(
        .OUTPUT_NODES(Conv3Out * Conv3Out * DepthC3)
    ) relu_3 (
        .clk      (clk),
        .reset    (Relu3Reset),
        .en       (enRelu),
        .input_fc (C3out),
        .output_fc(C3outRelu)
    );

    MaxPoolMulti #(
        .D(32),
        .H(6),
        .W(6)
    ) MP3 (
        .clk     (clk),
        .reset   (MP3rst),
        .apInput (C3outRelu),
        .apOutput(iConvOutput)
    );

    // === FSM Sequential Logic ===
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            state_counter <= 0;
        end else begin
            state <= next_state;
            if (state != next_state) state_counter <= 0;
            else state_counter <= state_counter + 1;
        end
    end

    // === FSM Next-State Logic ===
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: next_state = S_CONV1;
            S_CONV1:
            if (state_counter >= C1_CYCLES) begin
                // $display("Conv1 Output %h", C1out);
                next_state = S_RELU1;
            end
            S_RELU1:
            if (state_counter >= RELU1_CYCLES) begin
                // $display("ReLU1 Output %h", C1outRelu);
                next_state = S_MP1;
            end
            S_MP1:
            if (state_counter >= MP1_CYCLES) begin
                // $display("MP1 Output %h", MP1out);
                next_state = S_CONV2;
            end
            S_CONV2:
            if (state_counter >= C2_CYCLES) begin
                // $display("Conv2 Output %h", C2out);
                next_state = S_RELU2;
            end
            S_RELU2:
            if (state_counter >= RELU2_CYCLES) begin
                // $display("ReLU2 Output %h", C2outRelu);
                next_state = S_MP2;
            end
            S_MP2:
            if (state_counter >= MP2_CYCLES) begin
                // $display("MP2 Output %h", MP2out);
                next_state = S_CONV3;
            end
            S_CONV3:
            if (state_counter >= C3_CYCLES) begin
                // $display("Conv3 Output %h", C3out);
                next_state = S_RELU3;
            end
            S_RELU3:
            if (state_counter >= RELU3_CYCLES) begin
                // $display("ReLU3 Output %h", C3outRelu);
                next_state = S_MP3;
            end
            S_MP3:
            if (state_counter >= MP3_CYCLES) begin
                // $display("MP3 Output %h", iConvOutput);
                next_state = S_DONE;
            end
            S_DONE: next_state = S_DONE;
        endcase
    end

    // === FSM Output Logic (stage reset control) ===
    always @(*) begin
        // default all reset high
        if (reset) begin
            C1rst = 1;
            C2rst = 1;
            C3rst = 1;
            MP1rst = 1;
            MP2rst = 1;
            MP3rst = 1;
            Relu1Reset = 1;
            Relu2Reset = 1;
            Relu3Reset = 1;
            enRelu = 1;
        end


        case (state)
            S_CONV1: C1rst = (state != S_CONV1) ? 1 : 0;
            S_RELU1: Relu1Reset = (state != S_RELU1) ? 1 : 0;
            S_MP1:   MP1rst = (state != S_MP1) ? 1 : 0;
            S_CONV2: C2rst = (state != S_CONV2) ? 1 : 0;
            S_RELU2: Relu2Reset = (state != S_RELU2) ? 1 : 0;
            S_MP2:   MP2rst = (state != S_MP2) ? 1 : 0;
            S_CONV3: C3rst = (state != S_CONV3) ? 1 : 0;
            S_RELU3: Relu3Reset = (state != S_RELU3) ? 1 : 0;
            S_MP3:   MP3rst = (state != S_MP3) ? 1 : 0;
            default: ;  // keep reset
        endcase
    end

endmodule
