
module SORT_CNT_MEM #(
    parameter DATA_WIDTH = 8,   
    parameter ADDR_WIDTH = 4,  
    parameter NUM_BANKS  = 2,
    parameter REG_EN     = 1
)(
    input wire clk,
    input wire rst,
    input wire [NUM_BANKS   -1:0] wr_en,          
    input wire [NUM_BANKS   -1:0] rd_en, 
    input wire [ADDR_WIDTH  -1:0] wr_addr,
    input wire [ADDR_WIDTH  -1:0] rd_addr,
    input wire [NUM_BANKS*DATA_WIDTH-1:0] data_in, 
    output reg [NUM_BANKS*DATA_WIDTH-1:0] data_out 
);

genvar i;
integer j;

reg [DATA_WIDTH-1:0] memory [0:NUM_BANKS-1][0:(1<<ADDR_WIDTH)-1];

generate
if (REG_EN ==1) begin : GEN_CNT_MEM_USE_REG

    //wr
    for (i = 0; i < NUM_BANKS; i = i + 1) begin
        always @(posedge clk) begin
            if (~rst) begin
                for(j=0; j<(1<<ADDR_WIDTH); j=j+1) begin
                    memory[i][j] <= 0;
                end
            end
            else if (wr_en[i]) begin
                memory[i][wr_addr] <= data_in[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
            end
        end
    end

    //rd
    for (i = 0; i < NUM_BANKS; i = i + 1) begin : RD_BLOCK
            always @(posedge clk) begin
                if (rd_en[i]) begin
                    data_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] <= memory[i][rd_addr];
                end
            end
    end

end

else begin: GEN_CNT_MEM_USE_SRAM


    for (i=0; i< NUM_BANKS; i=i+1) begin
        SORT_DP_BANK_WRAP #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH),.NUM_BANKS(NUM_BANKS)) U_DP_BANK (
                    .clk                   (clk                                        ),
                    .rst                   (rst                                        ),
                    .wr_en                 (wr_en   [i]                                ),          
                    .rd_en                 (rd_en   [i]                                ), 
                    .wr_addr               (wr_addr                                    ),
                    .rd_addr               (rd_addr                                    ),
                    .data_in               (data_in [(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]), 
                    .data_out              (data_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH])

        );


    end


end
endgenerate

endmodule