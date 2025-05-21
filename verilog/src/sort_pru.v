
module SORT_PRU #( 
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM        ,
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM         ,
                  parameter  SORT_PERF_SBU_TILE_NUM   = `SORT_PERF_SBU_TILE_NUM  ,
                  parameter  SORT_FUC_REPEAT_NUM      = `SORT_FUC_REPEAT_NUM     ,
                  parameter  SORT_PERF_PREFETCH_DEPTH = `SORT_PERF_PREFETCH_DEPTH,
                  parameter  SORT_FUC_PREFETCH_EN     = `SORT_FUC_PREFETCH_EN    ,
                  parameter  SORT_PERF_OUTPORT_NUM    = `SORT_PERF_PARALLEL_OUT_NUM,

                  parameter  SORT_FUC_DATA_W          = $clog2(SORT_FUC_MAX_NUM),
                  parameter  SORT_FUC_CNT_MEM_DEPTH   = (SORT_FUC_MAX_NUM / SORT_FUC_BK_NUM),
                  parameter  SORT_FUC_SBU_TILE_W      = $clog2(SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_PERF_SBU_NUM        = (SORT_FUC_MAX_NUM) / (SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_FUC_SBU_ADDR_W      = $clog2(SORT_PERF_SBU_NUM),
                  parameter  SORT_FUC_CNT_MEM_W       = $clog2(SORT_FUC_REPEAT_NUM),
                  parameter  SORT_FUC_CNT_MEM_DEPTH_W = $clog2(SORT_FUC_CNT_MEM_DEPTH),
                  parameter  SORT_FUC_PREFETCH_DEPTH_W= $clog2(SORT_PERF_PREFETCH_DEPTH),
                  parameter  MEM_DATA_W               = SORT_FUC_CNT_MEM_W * SORT_FUC_BK_NUM,
                  parameter  SORT_FUC_BK_DEPTH_W      = $clog2(SORT_FUC_BK_NUM))
(
    input                                         clk                        ,
    input                                         rst                        ,  
    // CTRL
    input                                         ctrl2pru_start_vld_i       ,
    input                                         ctrl2pru_config_oder_en_i  ,

    // SBU
    input  wire                                   sbu2pru_rd_vld_i           ,
    input  wire [SORT_FUC_SBU_ADDR_W        -1:0] sbu2pru_rd_addr_i          ,
    input  wire                                   sbu2pru_rd_data_i          ,

    // CNT
    input  wire                                   cnt2pru_rd_1f_vld_i        ,
    input  wire                                   cnt2pru_rd_vld_i           ,
    input  wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] cnt2pru_rd_addr_i          ,
    input  wire [MEM_DATA_W                 -1:0] cnt2pru_rd_data_i          ,
    
    // TO SBU
    output wire                                   pru2sbu_rd_vld_o           ,
    output wire [SORT_FUC_SBU_ADDR_W        -1:0] pru2sbu_rd_addr_o          ,

    // TO CNT
    output wire                                   pru2cnt_rd_vld_o           ,
    output wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] pru2cnt_rd_addr_o          ,

    // TO CTRL
    output wire                                   pru2ctrl_rd_done_vld_o     ,

    // TO OUT
    output wire [SORT_PERF_OUTPORT_NUM      -1:0] pru2output_data_vld_o      ,

    output wire [SORT_PERF_OUTPORT_NUM * SORT_FUC_DATA_W -1:0] pru2output_data_o
);

parameter FIFO_DATA_W           = SORT_FUC_CNT_MEM_W + SORT_FUC_DATA_W  ;
parameter ALL_FIFO_DATA_W       = FIFO_DATA_W * SORT_PERF_PREFETCH_DEPTH;
parameter ALL_FIFO_DATA_SHIFT_W = $clog2(ALL_FIFO_DATA_W)               ;

wire [SORT_FUC_PREFETCH_DEPTH_W        :0] fifo_cnt                   ;
wire                                       pru_reg_cnt_rd_data_vld    ;
wire                                       pru_fsm_done_vld           ;

SORT_PRU_FSM #( 
                  .SORT_FUC_MAX_NUM             (`SORT_FUC_MAX_NUM        ),
                  .SORT_FUC_BK_NUM              (`SORT_FUC_BK_NUM         ),
                  .SORT_PERF_SBU_TILE_NUM       (`SORT_PERF_SBU_TILE_NUM  ),
                  .SORT_FUC_REPEAT_NUM          (`SORT_FUC_REPEAT_NUM     ),
                  .SORT_PERF_PREFETCH_DEPTH     (`SORT_PERF_PREFETCH_DEPTH),
                  .SORT_FUC_PREFETCH_EN         (`SORT_FUC_PREFETCH_EN    ))
U_SORT_PRU_PREFETCH_FSM (
                  .clk                          (clk                      ),
                  .rst                          (rst                      ),  

                  .ctrl2pru_start_vld_i         (ctrl2pru_start_vld_i     ),
                  .ctrl2pru_config_oder_en_i    (ctrl2pru_config_oder_en_i),
                  .sbu2pru_rd_vld_i             (sbu2pru_rd_vld_i         ),
                  .sbu2pru_rd_addr_i            (sbu2pru_rd_addr_i        ),
                  .sbu2pru_rd_data_i            (sbu2pru_rd_data_i        ),
                  .cnt2pru_rd_1f_vld_i          (cnt2pru_rd_1f_vld_i      ),
                  .cnt2pru_rd_vld_i             (cnt2pru_rd_vld_i         ),
                  .cnt2pru_rd_addr_i            (cnt2pru_rd_addr_i        ),
                  .fifo_cnt                     (fifo_cnt                 ),
                  .pru_reg_cnt_rd_data_vld      (pru_reg_cnt_rd_data_vld  ),

                  .pru_fsm_done_vld_o           (pru_fsm_done_vld         ),
                  .pru2sbu_rd_vld_o             (pru2sbu_rd_vld_o         ),
                  .pru2sbu_rd_addr_o            (pru2sbu_rd_addr_o        ),
                  .pru2cnt_rd_vld_o             (pru2cnt_rd_vld_o         ),
                  .pru2cnt_rd_addr_o            (pru2cnt_rd_addr_o        )
);

generate
if(SORT_FUC_PREFETCH_EN == 1) begin: GEN_PREFETCH_PRU_FSM

wire                                       oder_en                        ;

wire [SORT_FUC_PREFETCH_DEPTH_W      -1:0] fifo_rd_ptr                    ; 
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] fifo_rd_ptr_oh                 ; 
wire [SORT_FUC_PREFETCH_DEPTH_W      -1:0] fifo_rd_ptr_d                  ; 
wire [SORT_FUC_PREFETCH_DEPTH_W      -1:0] fifo_wr_ptr                    ; 
wire [SORT_FUC_PREFETCH_DEPTH_W      -1:0] fifo_wr_ptr_d                  ;  
wire [SORT_FUC_PREFETCH_DEPTH_W        :0] fifo_cnt_d                     ; 


wire [SORT_FUC_PREFETCH_DEPTH_W      -1:0] fifo_rd_addr                   [SORT_PERF_OUTPORT_NUM -1:0];
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] fifo_rd_addr_oh                [SORT_PERF_OUTPORT_NUM -1:0];

wire [FIFO_DATA_W                    -1:0] prefetch_fifo_rd_info          [SORT_PERF_OUTPORT_NUM -1:0];
wire [SORT_FUC_DATA_W                -1:0] prefetch_fifo_rd_idx_num       [SORT_PERF_OUTPORT_NUM -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] prefetch_fifo_rd_cnt_data      [SORT_PERF_OUTPORT_NUM -1:0];

wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wb_vld_pre       ;
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wb_vld           ; 
wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_wb_info_pre      ;
wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_wb_info          ; 
wire [SORT_FUC_BK_NUM                -1:0] cnt_rd_data_nzero_en           ;
wire [FIFO_DATA_W * SORT_FUC_BK_NUM  -1:0] prefetch_fifo_wr_nz_info       ;
reg  [SORT_FUC_BK_NUM                -1:0] prefetch_fifo_wr_nz_vld        ;
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wr_vld_pre       ;
wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_wr_info_pre_ext  ;
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wr_vld           ;
wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_cnt_wr_info      ;
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wr_en            ;
//wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_wr_info          ;
wire [SORT_PERF_PREFETCH_DEPTH       -1:0] prefetch_fifo_wr_reg_en        ;
wire [ALL_FIFO_DATA_W                -1:0] prefetch_fifo_info             ;

wire [ALL_FIFO_DATA_SHIFT_W          -1:0] wb_info_shift_num              ;
wire [ALL_FIFO_DATA_SHIFT_W          -1:0] wr_info_shift_num              ;

wire [SORT_FUC_BK_DEPTH_W              :0] cnt_rd_data_nzero_num          ;

wire                                       fifo_rd_upd_en                 ;
wire                                       fifo_wr_upd_en                 ;
wire                                       fifo_cnt_sub_en                ;
wire                                       fifo_cnt_sub_add_en            ;
wire                                       fifo_cnt_add_en                ;
wire                                       fifo_cnt_upd_en                ;
wire                                       prefetch_fsm_done_flag_upd_en  ;
wire                                       prefetch_fsm_done_flag         ;
wire [3                              -1:0] fifo_rd_cnt_sub                ;

wire [SORT_FUC_CNT_MEM_W             -1:0] cnt2pru_rd_bk_data             [SORT_FUC_BK_NUM          -1:0];
wire [SORT_FUC_BK_DEPTH_W            -1:0] prefetch_fifo_wr_bkid          [SORT_FUC_BK_NUM          -1:0];
wire [SORT_FUC_DATA_W                -1:0] prefetch_fifo_wr_idx_num       [SORT_FUC_BK_NUM          -1:0];
wire [FIFO_DATA_W                    -1:0] prefetch_fifo_wr_info_pre      [SORT_FUC_BK_NUM          -1:0];
reg  [FIFO_DATA_W                    -1:0] prefetch_fifo_wr_nz_info_pre   [SORT_FUC_BK_NUM          -1:0];
//reg  [SORT_FUC_CNT_MEM_W             -1:0] prefetch_fifo_wr_cnt_data      [SORT_FUC_BK_NUM          -1:0];
wire [FIFO_DATA_W                    -1:0] prefetch_fifo_wr_reg_info      [SORT_PERF_PREFETCH_DEPTH -1:0];
wire [FIFO_DATA_W                    -1:0] prefetch_fifo_reg_info         [SORT_PERF_PREFETCH_DEPTH -1:0];

wire [SORT_PERF_OUTPORT_NUM          -1:0] fifo_rd_en                     ;
wire [SORT_PERF_OUTPORT_NUM          -1:0] fifo_wr_wb_vld                 ;
wire [SORT_PERF_OUTPORT_NUM          -1:0] pru2output_data_vld            ;

wire [SORT_FUC_CNT_MEM_W             -1:0] fifo_wr_wb_cnt_data            [SORT_PERF_OUTPORT_NUM -1:0];

wire [SORT_PERF_OUTPORT_NUM * SORT_FUC_DATA_W -1:0] pru2output_data;
wire [SORT_PERF_OUTPORT_NUM * FIFO_DATA_W     -1:0] fifo_wr_wb_info_pre;

genvar i;

// input & output logic
assign pru2output_data_vld_o = pru2output_data_vld;
assign pru2output_data_o     = pru2output_data;

assign pru2ctrl_rd_done_vld_o= prefetch_fsm_done_flag & (fifo_cnt == 0) &
                               ~pru2cnt_rd_vld_o & ~cnt2pru_rd_1f_vld_i & ~cnt2pru_rd_vld_i;

assign pru_reg_cnt_rd_data_vld=0;

assign oder_en               = ctrl2pru_config_oder_en_i;

// Generate Output in parallel version of 1/2/4 port 

for(i=0; i<SORT_PERF_OUTPORT_NUM; i=i+1) begin: GEN_SORT_OUTPORT
    
    // FIFO rd
    assign fifo_rd_addr             [i] = fifo_rd_ptr + i;
    assign prefetch_fifo_rd_idx_num [i] = prefetch_fifo_rd_info[i][FIFO_DATA_W        -1:SORT_FUC_CNT_MEM_W];
    assign prefetch_fifo_rd_cnt_data[i] = prefetch_fifo_rd_info[i][SORT_FUC_CNT_MEM_W -1:                 0];

    CBB_BIN2ONEHOT #(.BIN_WIDTH(SORT_FUC_PREFETCH_DEPTH_W))            U_BIN2OH_GEN_REG_BK_EN (.bin_in(fifo_rd_addr[i]),.onehot_out(fifo_rd_addr_oh[i]));
    CBB_MUX       #(.WIDTH(FIFO_DATA_W), .N(SORT_PERF_PREFETCH_DEPTH)) U_MUX_GEN_FIFO_RD_DATA (.sel(fifo_rd_addr_oh[i]),.data_in(prefetch_fifo_info),.data_out(prefetch_fifo_rd_info[i]));

end

//port 0 (only have 1 port)
if (SORT_PERF_OUTPORT_NUM == 1) begin: GEN_OUTPUT_ONE_PORT
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx0_en;

    // generate fifo idx of output data 
    assign fifo_rd_idx0_en            [0] = fifo_cnt !=0;

    // generate fifo entry0 rd_ptr update en
    assign fifo_rd_en                 [0] = fifo_rd_idx0_en[0] & (prefetch_fifo_rd_cnt_data[0]==1);
    assign fifo_rd_upd_en                 = fifo_rd_en[0];
    assign fifo_rd_cnt_sub                = 1;
    // generate output data
    assign pru2output_data_vld        [                       0] = fifo_rd_idx0_en         [0];
    assign pru2output_data            [SORT_FUC_DATA_W     -1:0] = prefetch_fifo_rd_idx_num[0];

    // generate fifo wb en
    assign fifo_wr_wb_vld             [0] = fifo_rd_idx0_en[0];
    assign fifo_wr_wb_cnt_data        [0] = prefetch_fifo_rd_cnt_data[0] - 1;
    assign fifo_wr_wb_info_pre        [FIFO_DATA_W -1:0] = {prefetch_fifo_rd_idx_num[0],fifo_wr_wb_cnt_data[0]};
end
// port 0/1 (have 2 output port)
else if (SORT_PERF_OUTPORT_NUM == 2) begin: GEN_OUTPUT_TWO_PORT
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx0_en         ;
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx1_en         ;
    wire                               fifo_entry0_rd_cnt_eq2  ;
    wire                               fifo_entry0_rd_cnt_gte2 ;
    wire                               fifo_entry0_rd_cnt_eq1  ;
    wire                               fifo_entry1_rd_cnt_eq1  ;

    assign fifo_entry0_rd_cnt_eq2  = (prefetch_fifo_rd_cnt_data[0]==2);
    assign fifo_entry0_rd_cnt_gte2 = (prefetch_fifo_rd_cnt_data[0]>=2);
    assign fifo_entry0_rd_cnt_eq1  = (prefetch_fifo_rd_cnt_data[0]==1);
    assign fifo_entry1_rd_cnt_eq1  = (prefetch_fifo_rd_cnt_data[1]==1);

    // generate fifo idx of output data 
    assign fifo_rd_idx0_en            [0] = fifo_cnt !=0;
    assign fifo_rd_idx0_en            [1] = fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_gte2;
    assign fifo_rd_idx1_en            [0] = 1'b0;
    assign fifo_rd_idx1_en            [1] = fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_eq1 & (fifo_cnt>1);

    // generate fifo entry0 rd_ptr update en
    assign fifo_rd_en                 [0] =  fifo_rd_idx0_en[1] &                    & fifo_entry0_rd_cnt_eq2 |
                                            ~fifo_rd_idx0_en[1] & fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_eq1 ;
    assign fifo_rd_en                 [1] =  fifo_rd_idx1_en[1] &                      fifo_entry1_rd_cnt_eq1 ;
    assign fifo_rd_upd_en                 = fifo_rd_en[0] | fifo_rd_en[1];
    assign fifo_rd_cnt_sub                = fifo_rd_en[0] + fifo_rd_en[1];
    // generate output data
    assign pru2output_data_vld        [0] = fifo_rd_idx0_en[0];
    assign pru2output_data_vld        [1] = fifo_rd_idx0_en[1] | fifo_rd_idx1_en[1];

    assign pru2output_data            [SORT_FUC_DATA_W     -1:                0] = prefetch_fifo_rd_idx_num[0];
    assign pru2output_data            [SORT_FUC_DATA_W*2   -1:SORT_FUC_DATA_W  ] = fifo_rd_idx0_en[1] ? prefetch_fifo_rd_idx_num[0] :
                                                                                                        prefetch_fifo_rd_idx_num[1] ;

    // generate fifo wb en
    assign fifo_wr_wb_vld             [0] = fifo_rd_idx0_en[0] | fifo_rd_idx0_en[1];
    assign fifo_wr_wb_cnt_data        [0] = prefetch_fifo_rd_cnt_data[0] - (fifo_rd_idx0_en[0] + fifo_rd_idx0_en[1]);

    assign fifo_wr_wb_vld             [1] = fifo_rd_idx1_en[1] ;
    assign fifo_wr_wb_cnt_data        [1] = prefetch_fifo_rd_cnt_data[1] - 1'b1;

    assign fifo_wr_wb_info_pre        [FIFO_DATA_W   -1:          0] = {prefetch_fifo_rd_idx_num[0],fifo_wr_wb_cnt_data[0]};
    assign fifo_wr_wb_info_pre        [FIFO_DATA_W*2 -1:FIFO_DATA_W] = {prefetch_fifo_rd_idx_num[1],fifo_wr_wb_cnt_data[1]};
end
// port 0/1/2/3 (have 4 output port)
//         
//         case0 case1 case2 case3 case4 case5 case6 case7 (FIFO_rd_entry_num)
// port0   0     0     0     0     0     0     0     0
// port1   0     0     0     0     1     1     1     1
// port2   0     0     1     1     1     1     2     2
// port3   0     1     1     2     1     2     2     3
else begin: GEN_OUTPUT_FOUR_PORT
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx0_en         ;
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx1_en         ;
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx2_en         ;
    wire [SORT_PERF_OUTPORT_NUM  -1:0] fifo_rd_idx3_en         ;
    wire                               fifo_entry0_rd_cnt_eq1  ;
    wire                               fifo_entry0_rd_cnt_eq2  ;
    wire                               fifo_entry0_rd_cnt_eq3  ;
    wire                               fifo_entry0_rd_cnt_gte2 ;
    wire                               fifo_entry0_rd_cnt_gte3 ;
    wire                               fifo_entry0_rd_cnt_gte4 ;
    wire                               fifo_entry1_rd_cnt_eq1  ;
    wire                               fifo_entry1_rd_cnt_eq2  ; 
    wire                               fifo_entry1_rd_cnt_gte2 ;
    wire                               fifo_entry1_rd_cnt_gte3 ;
    wire                               fifo_entry2_rd_cnt_eq1  ;
    wire                               fifo_entry2_rd_cnt_gte2 ;
    wire                               fifo_cnt_gt1            ;
    wire                               fifo_cnt_gt2            ;
    wire                               fifo_cnt_gt3            ;
    wire [3                      -1:0] fifo_rd_en_sum0         ;
    wire [3                      -1:0] fifo_rd_en_sum1         ;
    wire [3                      -1:0] fifo_rd_en_sum2         ;
    wire [3                      -1:0] fifo_rd_en_sum3         ;

    assign fifo_entry0_rd_cnt_eq2  = (prefetch_fifo_rd_cnt_data[0]==2);
    assign fifo_entry0_rd_cnt_eq3  = (prefetch_fifo_rd_cnt_data[0]==3);
    assign fifo_entry0_rd_cnt_gte2 = (prefetch_fifo_rd_cnt_data[0]>=2);
    assign fifo_entry0_rd_cnt_gte3 = (prefetch_fifo_rd_cnt_data[0]>=3);
    assign fifo_entry0_rd_cnt_gte4 = (prefetch_fifo_rd_cnt_data[0]>=4);
    assign fifo_entry0_rd_cnt_eq1  = (prefetch_fifo_rd_cnt_data[0]==1);
    assign fifo_entry1_rd_cnt_eq1  = (prefetch_fifo_rd_cnt_data[1]==1);
    assign fifo_entry1_rd_cnt_eq2  = (prefetch_fifo_rd_cnt_data[1]==2);
    assign fifo_entry1_rd_cnt_gte2 = (prefetch_fifo_rd_cnt_data[1]>=2);
    assign fifo_entry1_rd_cnt_gte3 = (prefetch_fifo_rd_cnt_data[1]>=3);

    assign fifo_entry2_rd_cnt_eq1  = (prefetch_fifo_rd_cnt_data[2]==1);
    assign fifo_entry2_rd_cnt_gte2 = (prefetch_fifo_rd_cnt_data[2]>=2);
    assign fifo_cnt_gt1            = (fifo_cnt                    > 1);
    assign fifo_cnt_gt2            = (fifo_cnt                    > 2);
    assign fifo_cnt_gt3            = (fifo_cnt                    > 3);

    // generate fifo idx of output data 
    assign fifo_rd_idx0_en            [0] = fifo_cnt !=0; // 0xxx
    assign fifo_rd_idx0_en            [1] = fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_gte2; // 00xx
    assign fifo_rd_idx0_en            [2] = fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_gte3; // 000x
    assign fifo_rd_idx0_en            [3] = fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_gte4; // 0000

    assign fifo_rd_idx1_en            [0] =  1'b0;
    assign fifo_rd_idx1_en            [1] =  fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_eq1  & fifo_cnt_gt1; // 01xx
    assign fifo_rd_idx1_en            [2] = (fifo_rd_idx0_en[0] & fifo_rd_idx0_en[1] & fifo_entry0_rd_cnt_eq2 & fifo_cnt_gt1 ) | // 001x
                                            (fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_entry1_rd_cnt_gte2) ; // 011x

    assign fifo_rd_idx1_en            [3] = (fifo_rd_idx0_en[0] & fifo_entry0_rd_cnt_eq3  & fifo_cnt_gt1                           ) | // 0001
                                            (fifo_rd_idx0_en[0] & fifo_rd_idx0_en[1] & fifo_rd_idx1_en[2] & fifo_entry1_rd_cnt_gte2) | // 0011 (timing opt in future)
                                            (fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_rd_idx1_en[2] & fifo_entry1_rd_cnt_gte3) ; // 0111 (timing opt in future)

    assign fifo_rd_idx2_en            [0] =  1'b0;
    assign fifo_rd_idx2_en            [1] =  1'b0;
    assign fifo_rd_idx2_en            [2] =  fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_entry1_rd_cnt_eq1 & fifo_cnt_gt2; // 012x
    assign fifo_rd_idx2_en            [3] = (fifo_rd_idx0_en[0] & fifo_rd_idx0_en[1] & fifo_rd_idx1_en[2] & fifo_entry1_rd_cnt_eq1 & fifo_cnt_gt2) | // 0012
                                            (fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_rd_idx1_en[2] & fifo_entry1_rd_cnt_eq2 & fifo_cnt_gt2) | //0112 (timing opt in future)
                                            (fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_rd_idx2_en[2] & fifo_entry2_rd_cnt_gte2) ; // 0122 (timing opt in future)

    assign fifo_rd_idx3_en            [0] =  1'b0;
    assign fifo_rd_idx3_en            [1] =  1'b0;
    assign fifo_rd_idx3_en            [2] =  1'b0;
    assign fifo_rd_idx3_en            [3] = (fifo_rd_idx0_en[0] & fifo_rd_idx1_en[1] & fifo_rd_idx2_en[2] & fifo_entry2_rd_cnt_eq1 & fifo_cnt_gt3) ; // 0123 (timing opt in future)

    // generate fifo entry0 rd_ptr update en
    assign fifo_rd_en_sum0 = fifo_rd_idx0_en[0] + fifo_rd_idx0_en[1] + fifo_rd_idx0_en[2] + fifo_rd_idx0_en[3];
    assign fifo_rd_en_sum1 =                      fifo_rd_idx1_en[1] + fifo_rd_idx1_en[2] + fifo_rd_idx1_en[3];
    assign fifo_rd_en_sum2 =                                           fifo_rd_idx2_en[2] + fifo_rd_idx2_en[3];
    assign fifo_rd_en_sum3 =                                                                fifo_rd_idx3_en[3];

    assign fifo_rd_en                 [0] = (fifo_rd_en_sum0 == prefetch_fifo_rd_cnt_data[0]) & (fifo_rd_en_sum0 !=0);
    assign fifo_rd_en                 [1] = (fifo_rd_en_sum1 == prefetch_fifo_rd_cnt_data[1]) & (fifo_rd_en_sum1 !=0);
    assign fifo_rd_en                 [2] = (fifo_rd_en_sum2 == prefetch_fifo_rd_cnt_data[2]) & (fifo_rd_en_sum2 !=0);
    assign fifo_rd_en                 [3] = (fifo_rd_en_sum3 == prefetch_fifo_rd_cnt_data[3]) & (fifo_rd_en_sum3 !=0);
    assign fifo_rd_upd_en                 = fifo_rd_en[0] | fifo_rd_en[1] | fifo_rd_en[2] | fifo_rd_en[3];
    assign fifo_rd_cnt_sub                = fifo_rd_en[0] + fifo_rd_en[1] + fifo_rd_en[2] + fifo_rd_en[3];
    // generate output data
    assign pru2output_data_vld        [0] = fifo_rd_idx0_en[0] ;
    assign pru2output_data_vld        [1] = fifo_rd_idx0_en[1] | fifo_rd_idx1_en[1];
    assign pru2output_data_vld        [2] = fifo_rd_idx0_en[2] | fifo_rd_idx1_en[2] | fifo_rd_idx2_en[2];
    assign pru2output_data_vld        [3] = fifo_rd_idx0_en[3] | fifo_rd_idx1_en[3] | fifo_rd_idx2_en[3] | fifo_rd_idx3_en[3];

    assign pru2output_data            [SORT_FUC_DATA_W     -1:                0] = prefetch_fifo_rd_idx_num[0];
    assign pru2output_data            [SORT_FUC_DATA_W*2   -1:SORT_FUC_DATA_W  ] = fifo_rd_idx0_en[1] ? prefetch_fifo_rd_idx_num[0] :
                                                                                                        prefetch_fifo_rd_idx_num[1] ;
    assign pru2output_data            [SORT_FUC_DATA_W*3   -1:SORT_FUC_DATA_W*2] = {SORT_FUC_DATA_W{fifo_rd_idx0_en[2]}} & prefetch_fifo_rd_idx_num[0] |
                                                                                   {SORT_FUC_DATA_W{fifo_rd_idx1_en[2]}} & prefetch_fifo_rd_idx_num[1] |
                                                                                   {SORT_FUC_DATA_W{fifo_rd_idx2_en[2]}} & prefetch_fifo_rd_idx_num[2];


    assign pru2output_data            [SORT_FUC_DATA_W*4   -1:SORT_FUC_DATA_W*3] = {SORT_FUC_DATA_W{fifo_rd_idx0_en[3]}} & prefetch_fifo_rd_idx_num[0] |
                                                                                   {SORT_FUC_DATA_W{fifo_rd_idx1_en[3]}} & prefetch_fifo_rd_idx_num[1] |
                                                                                   {SORT_FUC_DATA_W{fifo_rd_idx2_en[3]}} & prefetch_fifo_rd_idx_num[2] |
                                                                                   {SORT_FUC_DATA_W{fifo_rd_idx3_en[3]}} & prefetch_fifo_rd_idx_num[3] ;

    // generate fifo wb en
    assign fifo_wr_wb_vld             [0] = fifo_rd_idx0_en[0] | fifo_rd_idx0_en[1] | fifo_rd_idx0_en[2] | fifo_rd_idx0_en[3];
    assign fifo_wr_wb_cnt_data        [0] = prefetch_fifo_rd_cnt_data[0] - fifo_rd_en_sum0;

    assign fifo_wr_wb_vld             [1] =                      fifo_rd_idx1_en[1] | fifo_rd_idx1_en[2] | fifo_rd_idx1_en[3];
    assign fifo_wr_wb_cnt_data        [1] = prefetch_fifo_rd_cnt_data[1] - fifo_rd_en_sum1;

    assign fifo_wr_wb_vld             [2] =                                           fifo_rd_idx2_en[2] | fifo_rd_idx2_en[3];
    assign fifo_wr_wb_cnt_data        [2] = prefetch_fifo_rd_cnt_data[2] - fifo_rd_en_sum2;

    assign fifo_wr_wb_vld             [3] =                                                                fifo_rd_idx3_en[3];
    assign fifo_wr_wb_cnt_data        [3] = prefetch_fifo_rd_cnt_data[3] - fifo_rd_en_sum3;

    assign fifo_wr_wb_info_pre        [FIFO_DATA_W   -1:            0] = {prefetch_fifo_rd_idx_num[0],fifo_wr_wb_cnt_data[0]};
    assign fifo_wr_wb_info_pre        [FIFO_DATA_W*2 -1:FIFO_DATA_W*1] = {prefetch_fifo_rd_idx_num[1],fifo_wr_wb_cnt_data[1]};
    assign fifo_wr_wb_info_pre        [FIFO_DATA_W*3 -1:FIFO_DATA_W*2] = {prefetch_fifo_rd_idx_num[2],fifo_wr_wb_cnt_data[2]};
    assign fifo_wr_wb_info_pre        [FIFO_DATA_W*4 -1:FIFO_DATA_W*3] = {prefetch_fifo_rd_idx_num[3],fifo_wr_wb_cnt_data[3]};  
end


// FIFO wr
// after rd, cnt_num need wr back
assign prefetch_fifo_wb_vld_pre  = {{(SORT_PERF_PREFETCH_DEPTH-SORT_PERF_OUTPORT_NUM){1'b0}}, fifo_wr_wb_vld};
assign prefetch_fifo_wb_info_pre = {{ALL_FIFO_DATA_W-FIFO_DATA_W*SORT_PERF_OUTPORT_NUM{1'b0}},fifo_wr_wb_info_pre};

assign wb_info_shift_num = fifo_rd_ptr*FIFO_DATA_W;
CBB_BARREL_SHIFTER #(.W(SORT_PERF_PREFETCH_DEPTH),.SHIFT_W(SORT_FUC_PREFETCH_DEPTH_W),.LFT_EN(1)) U_CBB_BARREL_SHIFT_WB_VLD  (.data_in(prefetch_fifo_wb_vld_pre ),.shift_amount(fifo_rd_ptr      ),.data_out(prefetch_fifo_wb_vld ));
CBB_BARREL_SHIFTER #(.W(ALL_FIFO_DATA_W         ),.SHIFT_W(ALL_FIFO_DATA_SHIFT_W    ),.LFT_EN(1)) U_CBB_BARREL_SHIFT_WB_DATA (.data_in(prefetch_fifo_wb_info_pre),.shift_amount(wb_info_shift_num),.data_out(prefetch_fifo_wb_info));

// from output to wr fifo
for(i=0; i<SORT_FUC_BK_NUM; i=i+1) begin: GEN_CNTU_RD_CNT
    assign cnt2pru_rd_bk_data          [i] = oder_en ? cnt2pru_rd_data_i[(SORT_FUC_BK_NUM-i)*SORT_FUC_CNT_MEM_W-1 : (SORT_FUC_BK_NUM-i-1)*SORT_FUC_CNT_MEM_W] :
                                                       cnt2pru_rd_data_i[(i+1)*SORT_FUC_CNT_MEM_W-1               : i*SORT_FUC_CNT_MEM_W                    ] ;
                                                       
    assign cnt_rd_data_nzero_en        [i] = (cnt2pru_rd_bk_data[i] != 0);
    assign prefetch_fifo_wr_bkid       [i] = oder_en ? (SORT_FUC_BK_NUM-1-i) : i; //oder_en ? i : SORT_FUC_BK_NUM-1-i;
    assign prefetch_fifo_wr_idx_num    [i] = {cnt2pru_rd_addr_i,prefetch_fifo_wr_bkid[i]};
    assign prefetch_fifo_wr_info_pre   [i] = {prefetch_fifo_wr_idx_num[i],cnt2pru_rd_bk_data[i]};

    assign prefetch_fifo_wr_nz_info[(i+1)*FIFO_DATA_W-1 : i*FIFO_DATA_W] = prefetch_fifo_wr_nz_info_pre [i];
end

integer idx;
integer j  ;
always @(*) begin
    for (idx=0; idx<SORT_FUC_BK_NUM; idx=idx+1) begin
        prefetch_fifo_wr_nz_vld         [idx] = 0;
        prefetch_fifo_wr_nz_info_pre    [idx] = 0;
    end
    j=0;
    for(idx=0; idx<SORT_FUC_BK_NUM; idx=idx+1) begin
        if(cnt_rd_data_nzero_en[idx]) begin
            prefetch_fifo_wr_nz_vld     [j] = cnt2pru_rd_vld_i;
            prefetch_fifo_wr_nz_info_pre[j] = prefetch_fifo_wr_info_pre[idx];
            j = j+1;
        end
    end
end

assign prefetch_fifo_wr_vld_pre      = {{SORT_PERF_PREFETCH_DEPTH-SORT_FUC_BK_NUM         {1'b0}},prefetch_fifo_wr_nz_vld  };
assign prefetch_fifo_wr_info_pre_ext = {{(ALL_FIFO_DATA_W-(FIFO_DATA_W * SORT_FUC_BK_NUM)){1'b0}},prefetch_fifo_wr_nz_info };

assign wr_info_shift_num = fifo_wr_ptr*FIFO_DATA_W;
CBB_BARREL_SHIFTER #(.W(SORT_PERF_PREFETCH_DEPTH),.SHIFT_W(SORT_FUC_PREFETCH_DEPTH_W),.LFT_EN(1)) U_CBB_BARREL_SHIFT_WR_VLD  (.data_in(prefetch_fifo_wr_vld_pre     ),.shift_amount(fifo_wr_ptr      ),.data_out(prefetch_fifo_wr_vld ));
CBB_BARREL_SHIFTER #(.W(ALL_FIFO_DATA_W         ),.SHIFT_W(ALL_FIFO_DATA_SHIFT_W    ),.LFT_EN(1)) U_CBB_BARREL_SHIFT_WR_DATA (.data_in(prefetch_fifo_wr_info_pre_ext),.shift_amount(wr_info_shift_num),.data_out(prefetch_fifo_cnt_wr_info));

assign prefetch_fifo_wr_en   = prefetch_fifo_wr_vld      | prefetch_fifo_wb_vld;

for(i=0; i<SORT_PERF_PREFETCH_DEPTH; i=i+1) begin: GEN_PREFETCH_FIFO
    assign prefetch_fifo_wr_reg_en  [i] = prefetch_fifo_wr_en  [i];
    assign prefetch_fifo_wr_reg_info[i] = {FIFO_DATA_W{prefetch_fifo_wr_vld[i]}} & prefetch_fifo_cnt_wr_info[(i+1)*FIFO_DATA_W-1 : i*FIFO_DATA_W] |
                                          {FIFO_DATA_W{prefetch_fifo_wb_vld[i]}} & prefetch_fifo_wb_info    [(i+1)*FIFO_DATA_W-1 : i*FIFO_DATA_W] ;

    CBB_REGE #(.WIDTH(FIFO_DATA_W),.INIT_VAL(0)) U_REG_FIFO_DATA (.clk(clk),.rst(rst),.en(prefetch_fifo_wr_reg_en[i]),.reg_d( prefetch_fifo_wr_reg_info[i]),.reg_q(prefetch_fifo_reg_info[i]));

    assign prefetch_fifo_info[(i+1)*FIFO_DATA_W-1 : i*FIFO_DATA_W] = prefetch_fifo_reg_info[i];
end

CBB_COUNT_ONES #(.WIDTH(SORT_FUC_BK_NUM)) U_COUNT_ONES_NZERO_NUM (.data_in(cnt_rd_data_nzero_en),.one_count(cnt_rd_data_nzero_num));

// regs condition and d val
assign fifo_wr_upd_en  = cnt2pru_rd_vld_i & (cnt_rd_data_nzero_num != 0 );

assign fifo_rd_ptr_d   = fifo_rd_ptr + fifo_rd_cnt_sub;
assign fifo_wr_ptr_d   = fifo_wr_ptr + cnt_rd_data_nzero_num;

assign fifo_cnt_sub_en     =  fifo_rd_upd_en & ~fifo_wr_upd_en;
assign fifo_cnt_sub_add_en =  fifo_rd_upd_en &  fifo_wr_upd_en;
assign fifo_cnt_add_en     = ~fifo_rd_upd_en &  fifo_wr_upd_en;
assign fifo_cnt_upd_en     =  fifo_rd_upd_en |
                              fifo_wr_upd_en ;

assign fifo_cnt_d          = {(SORT_FUC_PREFETCH_DEPTH_W +1){fifo_cnt_sub_en    }} & (fifo_cnt                        - fifo_rd_cnt_sub) |
                             {(SORT_FUC_PREFETCH_DEPTH_W +1){fifo_cnt_sub_add_en}} & (fifo_cnt +cnt_rd_data_nzero_num - fifo_rd_cnt_sub) |
                             {(SORT_FUC_PREFETCH_DEPTH_W +1){fifo_cnt_add_en    }} & (fifo_cnt +cnt_rd_data_nzero_num       ) ;

assign prefetch_fsm_done_flag_upd_en = pru_fsm_done_vld       | // set 
                                       pru2ctrl_rd_done_vld_o ; // clr

//regs
CBB_REGE #(.WIDTH(SORT_FUC_PREFETCH_DEPTH_W  ),.INIT_VAL(0)) U_REG_FIFO_RD_PTR  (.clk(clk),.rst(rst),.en(fifo_rd_upd_en ),.reg_d(fifo_rd_ptr_d),.reg_q(fifo_rd_ptr));
CBB_REGE #(.WIDTH(SORT_FUC_PREFETCH_DEPTH_W  ),.INIT_VAL(0)) U_REG_FIFO_WR_PTR  (.clk(clk),.rst(rst),.en(fifo_wr_upd_en ),.reg_d(fifo_wr_ptr_d),.reg_q(fifo_wr_ptr));
CBB_REGE #(.WIDTH(SORT_FUC_PREFETCH_DEPTH_W+1),.INIT_VAL(0)) U_REG_FIFO_CNT     (.clk(clk),.rst(rst),.en(fifo_cnt_upd_en),.reg_d(fifo_cnt_d   ),.reg_q(fifo_cnt   ));

CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_PFSM_DONE_FLG(.clk(clk),.rst(rst),.en(prefetch_fsm_done_flag_upd_en),.reg_d(pru_fsm_done_vld),.reg_q(prefetch_fsm_done_flag));

end

else begin: GEN_NOPREFETCH_PRU_FSM
wire                                       cnt_reg_data_vld           ;
wire                                       cnt_reg_rd_bk_data_nzero_en;

wire [SORT_FUC_DATA_W                -1:0] cnt_reg_num                ;
wire [MEM_DATA_W                     -1:0] cnt_reg_data               ;
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_reg_rd_data_idx        ;
wire [SORT_FUC_BK_NUM                -1:0] cnt_reg_rd_data_idx_oh     ;

wire                                       pru_fsm_done_flag          ;

wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_reg_rd_bk_data         ;

wire                                       cnt_reg_data_vld_clr_en    ;
wire                                       cnt_reg_data_vld_set_en    ;
wire                                       cnt_reg_data_vld_upd_en    ;
wire                                       cnt_reg_data_vld_d         ;

wire                                       cnt_reg_rd_data_idx_upd_en ;
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_reg_rd_data_idx_d      ;
wire                                       cnt_rd_data_upd_en         ;

wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_reg_bk_data            [SORT_FUC_BK_NUM -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt2pru_reg_bk_data_d      [SORT_FUC_BK_NUM -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] wb_cnt_reg_bk_data_d       [SORT_FUC_BK_NUM -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_reg_bk_data_d          [SORT_FUC_BK_NUM -1:0];

wire [MEM_DATA_W                     -1:0] cnt_reg_data_d             ;

wire [SORT_FUC_DATA_W                -1:0] cnt_reg_num_d              ;

wire                                       pru_fsm_done_flag_upd_en   ;
wire                                       pru_fsm_done_flag_d        ;

genvar i;

// input & output logic

assign pru2output_data_vld_o = cnt_reg_data_vld & cnt_reg_rd_bk_data_nzero_en;
assign pru2output_data_o     = cnt_reg_num;

assign pru2ctrl_rd_done_vld_o= pru_fsm_done_flag & ~cnt_reg_data_vld & ~pru2cnt_rd_vld_o & ~cnt2pru_rd_1f_vld_i & ~cnt2pru_rd_vld_i;;

assign pru_reg_cnt_rd_data_vld = cnt_reg_data_vld;

assign fifo_cnt = 0;
// rd bk data from reg

CBB_BIN2ONEHOT #(.BIN_WIDTH(SORT_FUC_BK_DEPTH_W)) U_BIN2OH_GEN_REG_BK_EN (.bin_in(cnt_reg_rd_data_idx),.onehot_out(cnt_reg_rd_data_idx_oh));

CBB_MUX #(.WIDTH(SORT_FUC_CNT_MEM_W), .N(SORT_FUC_BK_NUM)) U_MUX_GEN_REG_BK_DATA (.sel(cnt_reg_rd_data_idx_oh),.data_in(cnt_reg_data),.data_out(cnt_reg_rd_bk_data));

assign cnt_reg_rd_bk_data_nzero_en = cnt_reg_rd_bk_data!=0;

// reg data wr & upd

assign cnt_reg_data_vld_clr_en = cnt_reg_data_vld                             & 
                                (cnt_reg_rd_data_idx == 0                   ) &
                              (((cnt_reg_rd_bk_data == 1) & pru2output_data_vld_o) | (cnt_reg_rd_bk_data == 0));
assign cnt_reg_data_vld_set_en = cnt2pru_rd_vld_i;
assign cnt_reg_data_vld_upd_en = cnt_reg_data_vld_clr_en | cnt_reg_data_vld_set_en;
assign cnt_reg_data_vld_d      = cnt_reg_data_vld_set_en ;


assign cnt_reg_rd_data_idx_upd_en = cnt_reg_data_vld & 
                                 ( (cnt_reg_rd_bk_data==0) | ((cnt_reg_rd_bk_data==1) & pru2output_data_vld_o)) |
                                   pru2ctrl_rd_done_vld_o;
assign cnt_reg_rd_data_idx_d      = cnt_reg_rd_data_idx - 1; 

assign cnt_rd_data_upd_en         = cnt2pru_rd_vld_i | pru2output_data_vld_o;

for(i=0; i<SORT_FUC_BK_NUM; i=i+1) begin: GEN_NP_REG_DATA
    assign cnt_reg_bk_data      [i] = cnt_reg_data[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W];

    assign cnt2pru_reg_bk_data_d[i] = cnt2pru_rd_data_i[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W];
    assign wb_cnt_reg_bk_data_d [i] = (cnt_reg_rd_data_idx == i) ? (cnt_reg_bk_data[i] -1): cnt_reg_bk_data[i];

    assign cnt_reg_bk_data_d    [i] = cnt2pru_rd_vld_i ? cnt2pru_reg_bk_data_d[i] : wb_cnt_reg_bk_data_d[i];

    assign cnt_reg_data_d[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W] = cnt_reg_bk_data_d[i];

end

assign cnt_reg_num_d = pru2ctrl_rd_done_vld_o ? (SORT_FUC_MAX_NUM-1) : (cnt_reg_num-1);

assign pru_fsm_done_flag_upd_en = pru_fsm_done_vld | pru2ctrl_rd_done_vld_o;
assign pru_fsm_done_flag_d      = pru_fsm_done_vld ;

CBB_REGE #(.WIDTH(1                  ),.INIT_VAL(0                   )) U_NP_CNT_REG_VLD  (.clk(clk),.rst(rst),.en(cnt_reg_data_vld_upd_en   ),.reg_d(cnt_reg_data_vld_d    ),.reg_q(cnt_reg_data_vld   ));
CBB_REGE #(.WIDTH(MEM_DATA_W         ),.INIT_VAL(0                   )) U_NP_CNT_REG_DATA (.clk(clk),.rst(rst),.en(cnt_rd_data_upd_en        ),.reg_d(cnt_reg_data_d        ),.reg_q(cnt_reg_data       ));
CBB_REGE #(.WIDTH(SORT_FUC_BK_DEPTH_W),.INIT_VAL((SORT_FUC_BK_NUM-1) )) U_NP_CNT_REG_IDX  (.clk(clk),.rst(rst),.en(cnt_reg_rd_data_idx_upd_en),.reg_d(cnt_reg_rd_data_idx_d ),.reg_q(cnt_reg_rd_data_idx));
CBB_REGE #(.WIDTH(SORT_FUC_DATA_W    ),.INIT_VAL((SORT_FUC_MAX_NUM-1))) U_NP_CNT_REG_NUM  (.clk(clk),.rst(rst),.en(cnt_reg_rd_data_idx_upd_en),.reg_d(cnt_reg_num_d         ),.reg_q(cnt_reg_num        ));

CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_NPFSM_DONE_FLG(.clk(clk),.rst(rst),.en(pru_fsm_done_flag_upd_en),.reg_d(pru_fsm_done_flag_d),.reg_q(pru_fsm_done_flag));

end

endgenerate


endmodule