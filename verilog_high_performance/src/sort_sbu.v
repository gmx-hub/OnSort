
module SORT_SBU #( 
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM        ,
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM         ,
                  parameter  SORT_PERF_SBU_TILE_NUM   = `SORT_PERF_SBU_TILE_NUM  ,
                  parameter  SORT_FUC_REG_EN          = `SORT_FUC_REG_EN         ,

                  parameter  SORT_FUC_SBU_TILE_W      = $clog2(SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_PERF_SBU_NUM        = (SORT_FUC_MAX_NUM) / (SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_FUC_SBU_ADDR_W      = $clog2(SORT_PERF_SBU_NUM) )
(
    input                                         clk                        ,
    input                                         rst                        ,
    input  wire                                   agu2sbu_vld_i              ,
    input  wire [SORT_FUC_SBU_ADDR_W        -1:0] agu2sbu_addr_i             , 
    input  wire [SORT_FUC_SBU_TILE_W        -1:0] agu2sbu_id_i               ,
         
    input  wire                                   pru2sbu_rd_vld_i           ,
    input  wire [SORT_FUC_SBU_ADDR_W        -1:0] pru2sbu_rd_addr_i          ,
         
    output wire                                   sbu2pru_rd_vld_o           ,
    output wire [SORT_FUC_SBU_ADDR_W        -1:0] sbu2pru_rd_addr_o          ,
    output wire                                   sbu2pru_rd_data_o    
);

wire [SORT_PERF_SBU_NUM              -1:0] sbu_data              ;
wire                                       sbu_agu_wr_vld        ;
wire [SORT_PERF_SBU_NUM              -1:0] sbu_agu_wr_data_pre   ;
wire [SORT_PERF_SBU_NUM              -1:0] sbu_agu_wr_data       ;
wire                                       sbu_pru_clr_vld       ;
wire [SORT_PERF_SBU_NUM              -1:0] sbu_pru_clr_data_pre  ;
wire [SORT_PERF_SBU_NUM              -1:0] sbu_pru_clr_data      ;

wire                                       sbu_wr_vld            ;
wire [SORT_PERF_SBU_NUM              -1:0] sbu_wr_data           ;

genvar i;

// sbu output & rd 
assign sbu2pru_rd_vld_o  = pru2sbu_rd_vld_i           ;
assign sbu2pru_rd_addr_o = pru2sbu_rd_addr_i          ;
assign sbu2pru_rd_data_o = sbu_data[pru2sbu_rd_addr_i];

// sbu wr 
assign sbu_agu_wr_vld       = agu2sbu_vld_i;
assign sbu_agu_wr_data_pre  = 1 << agu2sbu_addr_i;
assign sbu_agu_wr_data      = sbu_agu_wr_data_pre | sbu_data;

assign sbu_pru_clr_vld      = pru2sbu_rd_vld_i;
assign sbu_pru_clr_data_pre = 1 << pru2sbu_rd_addr_i;
assign sbu_pru_clr_data     = ~sbu_pru_clr_data_pre & sbu_data;

assign sbu_wr_vld           = agu2sbu_vld_i | pru2sbu_rd_vld_i;
assign sbu_wr_data          = ({SORT_PERF_SBU_NUM{agu2sbu_vld_i   }} & sbu_agu_wr_data ) |
                              ({SORT_PERF_SBU_NUM{pru2sbu_rd_vld_i}} & sbu_pru_clr_data) ;

CBB_REGE #(.WIDTH(SORT_PERF_SBU_NUM),.INIT_VAL(0)) U_REG_SBU (.clk(clk),.rst(rst),.en(sbu_wr_vld),.reg_d(sbu_wr_data),.reg_q(sbu_data));



endmodule