// CNN_FGPA\CNN_FPGA.sim\sources_1\new\ANNfull.v
`timescale 1 ns / 1 ps

module ANNfull_TB ();

    parameter DATA_WIDTH = 32;
    parameter INPUT_NODES_L1 = 288;
    parameter INPUT_NODES_L2 = 120;
    parameter INPUT_NODES_L3 = 120;
    parameter INPUT_NODES_L4 = 84;
    parameter OUTPUT_NODES = 10;

    reg [DATA_WIDTH*INPUT_NODES_L1-1:0] input_ANN;
    reg clk, reset;
    wire [3:0] output_ANN;

    localparam PERIOD = 10;

    always #(PERIOD / 2) clk = ~clk;

    ANNfull #(
        .DATA_WIDTH(DATA_WIDTH),
        .INPUT_NODES_L1(INPUT_NODES_L1),
        .INPUT_NODES_L2(INPUT_NODES_L2),
        .INPUT_NODES_L3(INPUT_NODES_L3),
        .INPUT_NODES_L4(INPUT_NODES_L4),
        .OUTPUT_NODES(OUTPUT_NODES)
    ) UUT (
        .clk       (clk),
        .reset     (reset),
        .input_ANN (input_ANN),
        .output_ANN(output_ANN)
    );

    initial begin

        #0 clk = 1'b0;
        reset = 1'b1;
        // input_ANN = 32*288 = 9216 bit
        input_ANN = 9216'h3f2dd1903ee40a723eff47673ed9f09c3ec45f4e3ec5e0d33e5603603e4ff4b03dcc770abcf5c6f3bda65a1f3cb2a158bd53c44a3d60e0963cd3c5e4be1adbbabdae9161bdbc37d9be835fc3be5775dbbe18c420be30a718be0816debe731edcbdce5011be281f12be544f973eb0318f3e8c5d1b3e524e873f0118833eab04043e723f073ea4211f3e75f9403eaceb2cbe4b96023c4ec59dbd52e410bd861f013dc87a5fbd5f1100bd02a857bd623819be50fc1a3d5476833a53b73d3c8e672ebd8d4616be06f2e03d712213bd64aa83bda31ccd3e0d6e9bbd31e435bcc5786c3db7f766be20535abd72448b3c1355ecbe4e8abe3dd1cbafbde3f40e3d6f1bdbbde30b213c54cd343ca01fd43dd90cc23db098fe3b405a1f3e070c413ceb3807be1f4caebe1025a9bdecad89be30b034be00035bbd8f97313cb15d75be28e98bbdebfac7bd1452bbbe40cae0be3ada07be4a8adfbdf6fad8be38f884bdf19cecbe653fff3caeb7fe3d1d93fabe216778be680da1be176b62bd645573be0829e03d45e6c13d86027bbe1e93febde1da54bda322b2be4889abbdcc0fb3be4db48fbe634a65be500873be8a2a2bbe539545bec89430be9fbf62befa8c98bf0d085bbee569e9bf153d86bef7ab0fbf046636bec97fa03eba067b3dc6b5933e9565a33e8925483e4e41873ea7676e3d6272b23e0390763e875c11bd994b2bbcd7049e3d7cbe123df25e013dfc20a43c4a657fbd8f01963d9abdb93d1759673e9ef3873e4dab6f3ed3649b3df17943bd36b2363e3653143cab5822bd0c07283d9e72503cd4dbdfbcfedaa8bd330c40bd1414413c2c86323d2a58453b982563bd0caef6bb1430b53eb8243c3e0de5893ec3d5f63e06e7f13d6b32993e436c983e4a044f3e0ec92b3e92f111bc9db131bd48e2ccbd9f6b183d854ab8bd882c6f3d4c42893d97108bbd5ad6e53d01f9783d97db6b3d70778a3e391c323d84323c3ce7727f3e1b64eb3dcd79193e79d7e73e42eb743e6927a53e87456a3ec3b82c3ecaac763ead60833eaf723b3e5449403db94d813af947543e7b7a453dd3a9543e8a6b253e3e94ed3e1310443e238fbe3e9263ab3e7653643e61b129bf15118cbde3ebd5bf294555bf02007abe8f7834bf117ad8bec4d387be9de186beb7a9c7be34df4abe2dea59be6e3bd3bda3079abd9c81edbe690aafbe491f90be77247ebdd9a8e53d8906f3be2de71bbd9fc0bd3d75b2693cf163253e0a4c88bdbc3001bd7970fd3d43eb5c3c5775fcbc96a1033d811bf23d42439f3c746b9d3d051acb3e49880d3e2f934c3d4edbbdbcb1a55b3bfa13993d6357c33c555c7ebce71a153cf467963d886441bb12a45cbc9c29d93e4b72ba3e02dd393d405f5f3e7712063c161bd03d6448cf3dabfd4a3d74f30e3de7ec3e3d5bdc24be155267be0313dabd798e5abdfefc8dbe637814be34ead6bdf0fedabe9456483d230e84bcca5c983da939aebb08783ab9f848043c0587e3bd142843bcdc14663d3eda073eb6017d3e85b5de3eaee5b53eaf7b0d3e1aacf33e8a57b93edfcc243ebd63dd3edf33fc3dfd05533e0eebbe3e6a400d3df207ba3d3cc2a93e2e69163e0c95363e13125a3df63d3e;

        #(PERIOD * 10) reset = 1'b0;

        // #(PERIOD * 104)
        // #(PERIOD * 104)
        #(PERIOD * 700) $stop;

    end

endmodule
