

module SORT_TOP #( 
                  parameter  SORT_FUC_REPEAT_NUM      = `SORT_FUC_REPEAT_NUM       ,
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM          ,  
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM           ,
                  parameter  SORT_FUC_PREFETCH_EN     = `SORT_FUC_PREFETCH_EN      ,  
                  parameter  SORT_PERF_PREFETCH_DEPTH = `SORT_PERF_PREFETCH_DEPTH  ,
                  parameter  SORT_PERF_SBU_TILE_NUM   = `SORT_PERF_SBU_TILE_NUM    ,
                  parameter  SORT_FUC_ZERO_NUM        = `SORT_FUC_ZERO_NUM         ,
                  parameter  SORT_FUC_REG_EN          = `SORT_FUC_REG_EN           ,
                  parameter  SORT_PERF_OUTPORT_NUM    = `SORT_PERF_PARALLEL_OUT_NUM,

                  parameter  SORT_FUC_DATA_W          = $clog2(SORT_FUC_MAX_NUM)   ) 
(
    input                                    clk,
    input                                    rst,
 
    input  wire                              input_data_vld_i,
    input  wire [SORT_FUC_DATA_W       -1:0] input_data_i,
    input  wire                              input_data_done_vld_i,
    input  wire                              input_config_mode_i,

    output wire [SORT_PERF_OUTPORT_NUM -1:0] output_vld, 
    output wire                              output_done_vld,

    output wire [SORT_PERF_OUTPORT_NUM* SORT_FUC_DATA_W       -1:0] output_data
);
parameter SORT_PERF_SBU_NUM       = (SORT_FUC_MAX_NUM) / (SORT_PERF_SBU_TILE_NUM);
parameter SORT_FUC_CNT_MEM_DEPTH   = (SORT_FUC_MAX_NUM / SORT_FUC_BK_NUM);
parameter SORT_FUC_CNT_MEM_DEPTH_W = $clog2(SORT_FUC_CNT_MEM_DEPTH      );
parameter SORT_FUC_SBU_TILE_W      = $clog2(SORT_PERF_SBU_TILE_NUM      );
parameter SORT_FUC_BK_DEPTH_W      = $clog2(SORT_FUC_BK_NUM             );
parameter SORT_FUC_SBU_ADDR_W      = $clog2(SORT_PERF_SBU_NUM           );
parameter SORT_FUC_CNT_MEM_W       = $clog2(SORT_FUC_REPEAT_NUM         );
parameter MEM_DATA_W               = SORT_FUC_CNT_MEM_W * SORT_FUC_BK_NUM;


// AGU    
wire                                       agu2sbu_vld_o          ;
wire [SORT_FUC_SBU_ADDR_W            -1:0] agu2sbu_addr_o         ; 
wire [SORT_FUC_SBU_TILE_W            -1:0] agu2sbu_id_o           ;
wire                                       agu2cnt_vld_o          ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] agu2cnt_addr_o         ; 
wire [SORT_FUC_BK_DEPTH_W            -1:0] agu2cnt_bankid_o       ;

// CTRL
wire                                       cntu2ctrl_wr_done_vld_i;
wire                                       pru2ctrl_rd_done_vld_i ;
wire                                       ctrl2pru_start_vld_o   ;

// SBU
wire                                       sbu2pru_rd_vld_o       ;
wire [SORT_FUC_SBU_ADDR_W            -1:0] sbu2pru_rd_addr_o      ;
wire                                       sbu2pru_rd_data_o      ;  

// CNTU
wire                                       cnt2pru_rd_1f_vld_o    ;
wire                                       cnt2pru_rd_vld_o       ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt2pru_rd_addr_o      ;
wire [MEM_DATA_W                     -1:0] cnt2pru_rd_data_o      ;
wire                                       cntu2ctrl_wr_done_vld_o;

// RDU
wire                                       pru2sbu_rd_vld_o       ;
wire [SORT_FUC_SBU_ADDR_W            -1:0] pru2sbu_rd_addr_o      ;
wire                                       pru2cnt_rd_vld_o       ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] pru2cnt_rd_addr_o      ;
wire                                       pru2ctrl_rd_done_vld_o ;
wire [SORT_PERF_OUTPORT_NUM          -1:0] pru2output_data_vld_o  ;

wire [SORT_PERF_OUTPORT_NUM*SORT_FUC_DATA_W -1:0] pru2output_data_o; 

// input
//CBB_REG  #(.WIDTH(1              ),.INIT_VAL(0)) U_REG_IN_DATA_VLD (.clk(clk),.rst(rst),                      .reg_d(input_data_vld_i     ),.reg_q(input_data_vld     ));
//CBB_REGE #(.WIDTH(SORT_FUC_DATA_W),.INIT_VAL(0)) U_REG_IN_DATA     (.clk(clk),.rst(rst),.en(input_data_vld_i),.reg_d(input_data_i         ),.reg_q(input_data         ));
//CBB_REG  #(.WIDTH(1              ),.INIT_VAL(0)) U_REG_IN_DONE_VLD (.clk(clk),.rst(rst),                      .reg_d(input_data_done_vld_i),.reg_q(input_data_done_vld));
//CBB_REG  #(.WIDTH(1              ),.INIT_VAL(0)) U_REG_IN_CONFIG   (.clk(clk),.rst(rst),                      .reg_d(input_config_mode_i  ),.reg_q(input_config_mode  ));

// output
assign output_vld      = pru2output_data_vld_o  ;
assign output_done_vld = pru2ctrl_rd_done_vld_o ;
assign output_data     = pru2output_data_o      ;

SORT_AGU #(
          .SORT_FUC_MAX_NUM         (SORT_FUC_MAX_NUM             ),
          .SORT_FUC_BK_NUM          (SORT_FUC_BK_NUM              ),
          .SORT_PERF_SBU_TILE_NUM   (SORT_PERF_SBU_TILE_NUM       ))
U_SORT_AGU (
          .agu_data_vld_i           (input_data_vld_i             ),
          .agu_data_i               (input_data_i                 ),
          .agu2sbu_vld_o            (agu2sbu_vld_o                ),
          .agu2sbu_addr_o           (agu2sbu_addr_o               ),
          .agu2sbu_id_o             (agu2sbu_id_o                 ),
          .agu2cnt_vld_o            (agu2cnt_vld_o                ),
          .agu2cnt_addr_o           (agu2cnt_addr_o               ),
          .agu2cnt_bankid_o         (agu2cnt_bankid_o             )
);

SORT_CTRL U_SORT_CTRL(
    .clk                            (clk                          ),
    .rst                            (rst                          ),
    
    .ctrl_vld_i                     (input_data_vld_i             ),
    .ctrl_input_done_vld_i          (input_data_done_vld_i        ),

    .cntu2ctrl_wr_done_vld_i        (cntu2ctrl_wr_done_vld_o      ),
    .pru2ctrl_rd_done_vld_i         (pru2ctrl_rd_done_vld_o       ),

    .ctrl2pru_start_vld_o           (ctrl2pru_start_vld_o         )
);

SORT_SBU #( 
          .SORT_FUC_MAX_NUM         (SORT_FUC_MAX_NUM             ),
          .SORT_FUC_BK_NUM          (SORT_FUC_BK_NUM              ),
          .SORT_PERF_SBU_TILE_NUM   (SORT_PERF_SBU_TILE_NUM       ),
          .SORT_FUC_REG_EN          (SORT_FUC_REG_EN              ))
U_SORT_SBU
(
    .clk                            (clk                          ),
    .rst                            (rst                          ),

    .agu2sbu_vld_i                  (agu2sbu_vld_o                ),
    .agu2sbu_addr_i                 (agu2sbu_addr_o               ), 
    .agu2sbu_id_i                   (agu2sbu_id_o                 ),
 
    .pru2sbu_rd_vld_i               (pru2sbu_rd_vld_o             ),
    .pru2sbu_rd_addr_i              (pru2sbu_rd_addr_o            ),
  
    .sbu2pru_rd_vld_o               (sbu2pru_rd_vld_o             ),
    .sbu2pru_rd_addr_o              (sbu2pru_rd_addr_o            ),
    .sbu2pru_rd_data_o              (sbu2pru_rd_data_o            )
);

SORT_CNT_UNIT #( 
          .SORT_FUC_MAX_NUM         (SORT_FUC_MAX_NUM             ),
          .SORT_FUC_BK_NUM          (SORT_FUC_BK_NUM              ),
          .SORT_FUC_REPEAT_NUM      (SORT_FUC_REPEAT_NUM          ),
          .SORT_FUC_REG_EN          (SORT_FUC_REG_EN              ))
U_SORT_CNT_UNIT
(
    .clk                            (clk                          ),
    .rst                            (rst                          ),  
    // AGU
    .agu2cnt_vld_i                  (agu2cnt_vld_o                ),
    .agu2cnt_addr_i                 (agu2cnt_addr_o               ), 
    .agu2cnt_bankid_i               (agu2cnt_bankid_o             ),
    // RDU
    .pru2cnt_rd_vld_i               (pru2cnt_rd_vld_o             ),
    .pru2cnt_rd_addr_i              (pru2cnt_rd_addr_o            ),
    // TO RDU
    .cnt2pru_rd_1f_vld_o            (cnt2pru_rd_1f_vld_o          ),
    .cnt2pru_rd_vld_o               (cnt2pru_rd_vld_o             ),
    .cnt2pru_rd_addr_o              (cnt2pru_rd_addr_o            ),
    .cnt2pru_rd_data_o              (cnt2pru_rd_data_o            ),
    //TO CTRL
    .cntu2ctrl_wr_done_vld_o        (cntu2ctrl_wr_done_vld_o      )
);


SORT_PRU #( 
          .SORT_FUC_MAX_NUM         (SORT_FUC_MAX_NUM             ),
          .SORT_FUC_BK_NUM          (SORT_FUC_BK_NUM              ),
          .SORT_PERF_SBU_TILE_NUM   (SORT_PERF_SBU_TILE_NUM       ),
          .SORT_FUC_REPEAT_NUM      (SORT_FUC_REPEAT_NUM          ),
          .SORT_PERF_PREFETCH_DEPTH (SORT_PERF_PREFETCH_DEPTH     ),
          .SORT_FUC_PREFETCH_EN     (SORT_FUC_PREFETCH_EN         ),
          .SORT_PERF_OUTPORT_NUM    (SORT_PERF_OUTPORT_NUM        ))
U_SROT_PRU (
    .clk                            (clk                          ),
    .rst                            (rst                          ), 
    // CTRL
    .ctrl2pru_start_vld_i           (ctrl2pru_start_vld_o         ),
    .ctrl2pru_config_oder_en_i      (input_config_mode_i          ),
    // SBU
    .sbu2pru_rd_vld_i               (sbu2pru_rd_vld_o             ),
    .sbu2pru_rd_addr_i              (sbu2pru_rd_addr_o            ),
    .sbu2pru_rd_data_i              (sbu2pru_rd_data_o            ),
    // CNT
    .cnt2pru_rd_1f_vld_i            (cnt2pru_rd_1f_vld_o          ),
    .cnt2pru_rd_vld_i               (cnt2pru_rd_vld_o             ),
    .cnt2pru_rd_addr_i              (cnt2pru_rd_addr_o            ),
    .cnt2pru_rd_data_i              (cnt2pru_rd_data_o            ),
    // TO SBU
    .pru2sbu_rd_vld_o               (pru2sbu_rd_vld_o             ),
    .pru2sbu_rd_addr_o              (pru2sbu_rd_addr_o            ),
    // TO CNT
    .pru2cnt_rd_vld_o               (pru2cnt_rd_vld_o             ),
    .pru2cnt_rd_addr_o              (pru2cnt_rd_addr_o            ),
    // TO CTRL
    .pru2ctrl_rd_done_vld_o         (pru2ctrl_rd_done_vld_o       ),
    // TO OUT
    .pru2output_data_vld_o          (pru2output_data_vld_o        ),
    .pru2output_data_o              (pru2output_data_o            )
);



endmodule