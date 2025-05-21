module CBB_COUNT_ONES #(
    parameter WIDTH = 8, 
    parameter OUT_CNT_W = $clog2(WIDTH) + 1
)(
    input [WIDTH-1:0] data_in,
    output reg [OUT_CNT_W -1:0] one_count 
);

    integer i;

    always @(*) begin
        one_count = 0; 
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (data_in[i] == 1) begin
                one_count = one_count + 1;
            end
        end
    end

endmodule