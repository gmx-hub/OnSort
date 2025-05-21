`include "../../cbb/bin2onehot.v"

module tb_CBB_BIN2ONEHOT;

    parameter BIN_WIDTH = 3;
    parameter ONEHOT_WIDTH = 1 << BIN_WIDTH;

    reg [BIN_WIDTH-1:0] bin_in;
    wire [ONEHOT_WIDTH-1:0] onehot_out;

    // 实例化 CBB_BIN2ONEHOT 模块
    CBB_BIN2ONEHOT #(BIN_WIDTH) uut (
        .bin_in(bin_in),
        .onehot_out(onehot_out)
    );

    initial begin
        // 测试不同的二进制输入
        bin_in = 3'b000; #10;
        bin_in = 3'b001; #10;
        bin_in = 3'b010; #10;
        bin_in = 3'b011; #10;
        bin_in = 3'b100; #10;
        bin_in = 3'b101; #10;
        bin_in = 3'b110; #10;
        bin_in = 3'b111; #10;

        // 结束仿真
        $finish;
    end

    // 监视输入和输出的变化
    initial begin
        $monitor("At time %t, bin_in = %b, onehot_out = %b", $time, bin_in, onehot_out);
    end

endmodule