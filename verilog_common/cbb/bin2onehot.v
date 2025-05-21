

module CBB_BIN2ONEHOT #(
    parameter BIN_WIDTH = 3,  
    parameter ONEHOT_WIDTH = 1 << BIN_WIDTH 
)(
    input wire [BIN_WIDTH   -1:0] bin_in    ,
    output reg [ONEHOT_WIDTH-1:0] onehot_out
);

integer i;

generate
    always @(*) begin
        onehot_out = 0;
        for (i = 0; i<ONEHOT_WIDTH; i=i+1 ) begin
            if(i == bin_in)
                onehot_out[i] = 1'b1;
            else 
                onehot_out[i] = 1'b0;
        end
    end
endgenerate

endmodule