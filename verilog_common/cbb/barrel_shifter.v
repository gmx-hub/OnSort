module CBB_BARREL_SHIFTER #(
    parameter W       = 8     ,
    parameter SHIFT_W = 32    ,
    parameter LFT_EN  = 1     
)(
    input  wire [W       -1:0] data_in,  
    input  wire [SHIFT_W -1:0] shift_amount,  // right shift number
    output reg  [W       -1:0] data_out  
);

if(LFT_EN ==0) begin
    always @(*) begin
        // barrel right shift 
        data_out = (data_in >> shift_amount) | (data_in << (W - shift_amount));
    end
end
else if(LFT_EN ==1) begin
    always @(*) begin
        // circular right shift
        data_out = (data_in << shift_amount) | (data_in >> (W - shift_amount));
    end
end


endmodule