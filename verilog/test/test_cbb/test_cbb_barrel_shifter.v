`include "../../cbb/barrel_shifter.v"

module tb_barrel_shifter;

    parameter N = 8;  // 与模块参数保持一致
    reg [N-1:0] data_in;
    reg [31:0] shift_amount;
    wire [N-1:0] data_out;

    CBB_BARREL_SHIFTER #(.W(N),.SHIFT_W(32)) uut (
        .data_in(data_in),
        .shift_amount(shift_amount),
        .data_out(data_out)
    );

    initial begin
        // 初始化输入
        data_in = 8'b10101010;
        shift_amount = 3;
        #10;
        $display("Data: %b, Shift amount: %0d, Result: %b", data_in, shift_amount, data_out);
        
        data_in = 8'b11110000;
        shift_amount = 4;
        #10;
        $display("Data: %b, Shift amount: %0d, Result: %b", data_in, shift_amount, data_out);
        
        data_in = 8'b00001111;
        shift_amount = 5;
        #10;
        $display("Data: %b, Shift amount: %0d, Result: %b", data_in, shift_amount, data_out);
        
        data_in = 8'b10000001;
        shift_amount = 7;
        #10;
        $display("Data: %b, Shift amount: %0d, Result: %b", data_in, shift_amount, data_out);

        $finish;
    end

endmodule