module SORT_DP_BANK_WRAP #( 
    parameter ADDR_WIDTH     = 4 ,
    parameter DATA_WIDTH     = 10,
    parameter NUM_BANKS      = 8 
)(
    input  wire                            clk            ,
    input  wire                            rst            ,

    input  wire                            wr_vld         ,
    input  wire [ADDR_WIDTH          -1:0] wr_addr        ,
    input  wire [DATA_WIDTH          -1:0] data_in        ,    

    input  wire                            rd_vld         ,
    input  wire [ADDR_WIDTH          -1:0] rd_addr        ,

    output wire [DATA_WIDTH          -1:0] data_out   
);

generate
    // N = 65536  depth=8192(2*4096) bidwith=10
    if ((ADDR_WIDTH == 13) & (NUM_BANKS == 8)) begin: GEN_MEM_65536
        wire                   sram_ce0;
        wire                   sram_ce1;
        wire                   sram_ce0_1f;
        wire                   sram_ce1_1f;

        wire                   sram_we0;
        wire                   sram_we1;

        wire [DATA_WIDTH -1:0] rd_data0;
        wire [DATA_WIDTH -1:0] rd_data1;

        assign sram_ce0 = (rd_vld &  rd_addr[ADDR_WIDTH-1]) | (wr_vld &  wr_addr[ADDR_WIDTH-1]);
        assign sram_ce1 = (rd_vld & ~rd_addr[ADDR_WIDTH-1]) | (wr_vld & ~wr_addr[ADDR_WIDTH-1]) ;

        assign sram_we0 = wr_vld &  wr_addr[ADDR_WIDTH-1];
        assign sram_we1 = wr_vld & ~wr_addr[ADDR_WIDTH-1];

        CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_CE0_1F_VLD (.clk(clk),.rst(rst),.reg_d(sram_ce0),.reg_q(sram_ce0_1f));
        CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_CE1_1F_VLD (.clk(clk),.rst(rst),.reg_d(sram_ce1),.reg_q(sram_ce1_1f));

        assign data_out = sram_ce0_1f ? rd_data0 : sram_we1;

        //sram0
         U_4096x10bitDPRAM0 (
                    .SLP          (),
                    .SD           (),
                    .CLK          (clk), 
                    .CEB          (~sram_ce),
                    .WEB          (~wr_vld),
                    .CEBM         (), 
                    .WEBM         (),
                    .A            (sram_addr), 
                    .D            (sram0_data_in),
                    .AM           (), 
                    .DM           (), 
                    .BIST         (),
                    .Q            (sram0_data_out)
        );
        
        //sram1
         U_32x128bitSPRAM1 (
                    .SLP          (),
                    .SD           (),
                    .CLK          (clk), 
                    .CEB          (sram_ce),
                    .WEB          (wr_vld),
                    .CEBM         (), 
                    .WEBM         (),
                    .A            (sram_addr), 
                    .D            (sram1_data_in),
                    .AM           (), 
                    .DM           (), 
                    .BIST         (),
                    .Q            (sram1_data_out)
        );

    end
    // N = 16384 depth=2048 bidwith=10
    else if ((ADDR_WIDTH == 11) & (NUM_BANKS == 8)) begin: GEN_MEM_16384
        wire sram_ce;
        assign sram_ce = rd_vld | wr_vld;
    end
    // N = 8192 depth=1024 bidwith=10
    else if ((ADDR_WIDTH == 10) & (NUM_BANKS == 8)) begin: GEN_MEM_8192
        wire sram_ce;
        assign sram_ce = rd_vld | wr_vld;
    end
    // N = 1024 depth=128 bidwith=10
    else if ((ADDR_WIDTH ==  7) & (NUM_BANKS == 8)) begin: GEN_MEM_1024
        wire sram_ce;
        assign sram_ce = rd_vld | wr_vld;
    end

endgenerate

wire [8*16       -1:0] sram0_data_in;
wire [8*16       -1:0] sram1_data_in;

wire [8*16       -1:0] sram0_data_out;
wire [8*16       -1:0] sram1_data_out;

wire [ADDR_WIDTH -1:0] sram_addr;

wire sram_ce;

assign sram_ce   =  (wr_vld | rd_vld);
assign sram_addr = {ADDR_WIDTH{rd_vld}} & rd_addr |
                   {ADDR_WIDTH{wr_vld}} & wr_addr ;

assign sram0_data_in = data_in[ 8*16-1:   0];
assign sram1_data_in = data_in[16*16-1:8*16];

assign data_out = {sram1_data_out,sram0_data_out};

//bk1
TS1N28HPCPHVTB32X128M4SBSO U_32x128bitSPRAM0 (
            .SLP          (),
            .SD           (),
            .CLK          (clk), 
            .CEB          (~sram_ce),
            .WEB          (~wr_vld),
            .CEBM         (), 
            .WEBM         (),
            .A            (sram_addr), 
            .D            (sram0_data_in),
            .AM           (), 
            .DM           (), 
            .BIST         (),
            .Q            (sram0_data_out)
);


//bk2
TS1N28HPCPHVTB32X128M4SBSO U_32x128bitSPRAM1 (
            .SLP          (),
            .SD           (),
            .CLK          (clk), 
            .CEB          (sram_ce),
            .WEB          (wr_vld),
            .CEBM         (), 
            .WEBM         (),
            .A            (sram_addr), 
            .D            (sram1_data_in),
            .AM           (), 
            .DM           (), 
            .BIST         (),
            .Q            (sram1_data_out)
);


endmodule
