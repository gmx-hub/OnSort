`include "../../cbb/count_ones.v"

module tb_count_ones;

    parameter WIDTH = 8;  // 与模块参数保持一致
    parameter OUT_CNT_W = ($clog2(WIDTH) + 1);

    reg [WIDTH-1:0] data_in;
    wire [OUT_CNT_W-1:0] one_count;

    CBB_COUNT_ONES #(WIDTH) uut (
        .data_in(data_in),
        .one_count(one_count)
    );

    initial begin
        // 初始化输入
        data_in = 8'b00000000;
        #10;
        $display("Data: %b, Count of 1s: %0d", data_in, one_count);
        
        data_in = 8'b10101010;
        #10;
        $display("Data: %b, Count of 1s: %0d", data_in, one_count);
        
        data_in = 8'b11110000;
        #10;
        $display("Data: %b, Count of 1s: %0d", data_in, one_count);
        
        data_in = 8'b11111111;
        #10;
        $display("Data: %b, Count of 1s: %0d", data_in, one_count);

        $finish;
    end

endmodule