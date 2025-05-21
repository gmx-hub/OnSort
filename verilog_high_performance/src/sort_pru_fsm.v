

module SORT_PRU_FSM #( 
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM        ,
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM         ,
                  parameter  SORT_PERF_SBU_TILE_NUM   = `SORT_PERF_SBU_TILE_NUM  ,
                  parameter  SORT_FUC_REPEAT_NUM      = `SORT_FUC_REPEAT_NUM     ,
                  parameter  SORT_PERF_PREFETCH_DEPTH = `SORT_PERF_PREFETCH_DEPTH,
                  parameter  SORT_FUC_PREFETCH_EN     = `SORT_FUC_PREFETCH_EN    ,

                  parameter  SORT_FUC_CNT_MEM_DEPTH   = (SORT_FUC_MAX_NUM / SORT_FUC_BK_NUM),
                  parameter  SORT_FUC_SBU_TILE_W      = $clog2(SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_PERF_SBU_NUM        = (SORT_FUC_MAX_NUM) / (SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_FUC_SBU_ADDR_W      = $clog2(SORT_PERF_SBU_NUM),
                  parameter  SORT_FUC_CNT_MEM_W       = $clog2(SORT_FUC_REPEAT_NUM),
                  parameter  SORT_FUC_CNT_MEM_DEPTH_W = $clog2(SORT_FUC_CNT_MEM_DEPTH),
                  parameter  SORT_FUC_PREFETCH_DEPTH_W= $clog2(SORT_PERF_PREFETCH_DEPTH))
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

    // PRU TOP
    input  wire [SORT_FUC_PREFETCH_DEPTH_W    :0] fifo_cnt                   ,// For prefetch   fsm
    input  wire                                   pru_reg_cnt_rd_data_vld    ,// For noprefetch fsm

    // TO PRU TOP
    output wire                                   pru_fsm_done_vld_o         ,
    
    // TO SBU
    output wire                                   pru2sbu_rd_vld_o           ,
    output wire [SORT_FUC_SBU_ADDR_W        -1:0] pru2sbu_rd_addr_o          ,

    // TO CNT
    output wire                                   pru2cnt_rd_vld_o           ,
    output wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] pru2cnt_rd_addr_o
);

parameter IDLE            = 0                   ;
parameter NEW_SBU         = IDLE    + 1         ;
parameter CNT_MEM         = NEW_SBU + 1         ;
parameter STATE_W         = $clog2(CNT_MEM+1)   ;
parameter SBU_CNT_MAX_VAL = SORT_PERF_SBU_NUM -1;
parameter MEM_CNT_MAX_VAL = (SORT_PERF_SBU_TILE_NUM/SORT_FUC_BK_NUM) -1;
parameter SBU_CNT_W       = SORT_FUC_SBU_ADDR_W ;
parameter MEM_CNT_W       = $clog2(SORT_PERF_SBU_TILE_NUM/SORT_FUC_BK_NUM);

parameter NPREFETCH_IDLE            = 0                           ;
parameter NPREFETCH_CNT_MEM         = NPREFETCH_IDLE + 1          ;
parameter NPREFETCH_STATE_W         = $clog2(NPREFETCH_CNT_MEM+1) ;
parameter NPREFETCH_MEM_CNT_MAX_VAL = SORT_FUC_CNT_MEM_DEPTH - 1  ;
parameter NPREFETCH_MEM_CNT_W       = SORT_FUC_CNT_MEM_DEPTH_W    ;

parameter PREFETCH_CNT2_EN = SORT_PERF_PREFETCH_DEPTH >= 3*SORT_FUC_BK_NUM;
parameter PREFETCH_CNT1_EN = SORT_PERF_PREFETCH_DEPTH >= 2*SORT_FUC_BK_NUM;
parameter PREFETCH_CNT0_EN = SORT_PERF_PREFETCH_DEPTH >=   SORT_FUC_BK_NUM;


generate 
    if (SORT_FUC_PREFETCH_EN ==1) begin : GEN_PREFETCH_FSM

        wire                                       oder_en                    ;
    
        wire                                       cur_state_idle_en          ;
        wire                                       cur_state_new_sbu_en       ;
        wire                                       cur_state_cnt_mem_en       ;
        wire                                       fifo_rest_en               ;
        wire                                       cur_idle_nxt_idle_en       ;
        wire                                       cur_sbu_nxt_idle_en_pre    ;
        wire                                       cur_sbu_nxt_idle_en        ;
        wire                                       cur_mem_nxt_idle_en_pre    ;
        wire                                       cur_mem_nxt_idle_en        ;
        wire                                       next_state_idle_en         ;
        wire [SBU_CNT_W                      -1:0] nxt_idle_prefetch_sbu_cnt_d;
        wire [MEM_CNT_W                      -1:0] nxt_idle_prefetch_mem_cnt_d;
        wire                                       cur_idle_nxt_sbu_en        ;
        wire                                       cur_sbu_nxt_sbu_en_pre     ;
        wire                                       cur_sbu_nxt_sbu_en         ;
        wire                                       cur_mem_nxt_sbu_en_pre     ;
        wire                                       cur_mem_nxt_sbu_en         ;
        wire                                       next_state_sbu_en          ;
        wire [SBU_CNT_W                      -1:0] cur_idle_nxt_sbu_sbu_cnt   ;
        wire [SBU_CNT_W                      -1:0] cur_other_nxt_sbu_sbu_cnt  ;
        wire [SBU_CNT_W                      -1:0] nxt_sbu_prefetch_sbu_cnt_d ;
        wire [MEM_CNT_W                      -1:0] nxt_sbu_prefetch_mem_cnt_d ;
        wire                                       cur_sbu_nxt_mem_en         ;
        wire                                       cur_mem_nxt_mem_en_pre     ;
        wire                                       cur_mem_nxt_mem_en         ;
        wire                                       next_state_mem_en          ;
        wire [SBU_CNT_W                      -1:0] nxt_mem_prefetch_sbu_cnt_d ;
        wire [MEM_CNT_W                      -1:0] nxt_mem_prefetch_mem_cnt_d ;
        wire                                       next_state_upd_en          ;
        wire [STATE_W                        -1:0] next_state                 ;
        wire [STATE_W                        -1:0] prefetch_state             ;
        wire                                       cnt_upd_en                 ;
        wire [SBU_CNT_W                      -1:0] prefetch_sbu_cnt_d         ;
        wire [MEM_CNT_W                      -1:0] prefetch_mem_cnt_d         ;
        wire [SBU_CNT_W                      -1:0] prefetch_sbu_cnt           ;
        wire [MEM_CNT_W                      -1:0] prefetch_mem_cnt           ;
        wire [MEM_CNT_W+SBU_CNT_W            -1:0] pru2cnt_rd_addr_pre        ;
        // input & output
        assign oder_en = ctrl2pru_config_oder_en_i;

        assign pru2sbu_rd_vld_o        = cur_state_new_sbu_en;
        assign pru2sbu_rd_addr_o       = prefetch_sbu_cnt    ;

        assign pru2cnt_rd_vld_o        = fifo_rest_en                                 &
                                         ((cur_state_new_sbu_en & cur_sbu_nxt_mem_en) |
                                           cur_state_cnt_mem_en                     ) ;
        assign pru2cnt_rd_addr_o       = {prefetch_sbu_cnt,prefetch_mem_cnt};

        assign pru_fsm_done_vld_o      = cur_mem_nxt_idle_en | cur_sbu_nxt_idle_en;
        // FSM
        assign cur_state_idle_en    = (prefetch_state == IDLE   );
        assign cur_state_new_sbu_en = (prefetch_state == NEW_SBU);
        assign cur_state_cnt_mem_en = (prefetch_state == CNT_MEM);    

        assign fifo_rest_en0 = ((cnt2pru_rd_1f_vld_i  &  cnt2pru_rd_vld_i) & (fifo_cnt <= (SORT_PERF_PREFETCH_DEPTH - 3*SORT_FUC_BK_NUM)) & PREFETCH_CNT2_EN);
        assign fifo_rest_en1 = ((cnt2pru_rd_1f_vld_i  ^  cnt2pru_rd_vld_i) & (fifo_cnt <= (SORT_PERF_PREFETCH_DEPTH - 2*SORT_FUC_BK_NUM)) & PREFETCH_CNT1_EN);
        assign fifo_rest_en2 = ((~cnt2pru_rd_1f_vld_i & ~cnt2pru_rd_vld_i) & (fifo_cnt <= (SORT_PERF_PREFETCH_DEPTH -   SORT_FUC_BK_NUM)) & PREFETCH_CNT0_EN);
        assign fifo_rest_en = fifo_rest_en0 | fifo_rest_en1 | fifo_rest_en2;
                              

        // next state idle & behavior
        // next state idle condition
        assign cur_idle_nxt_idle_en     = cur_state_idle_en & ~ctrl2pru_start_vld_i;

        assign cur_sbu_nxt_idle_en_pre  = oder_en ? (prefetch_sbu_cnt == 0) : (prefetch_sbu_cnt == SBU_CNT_MAX_VAL);
        assign cur_sbu_nxt_idle_en      = cur_state_new_sbu_en & 
                                          sbu2pru_rd_vld_i     &
                                         ~sbu2pru_rd_data_i    &
                                          cur_sbu_nxt_idle_en_pre;

        assign cur_mem_nxt_idle_en_pre  = oder_en ? (prefetch_sbu_cnt == 0              ) & (prefetch_mem_cnt == 0              ) :
                                                    (prefetch_sbu_cnt == SBU_CNT_MAX_VAL) & (prefetch_mem_cnt == MEM_CNT_MAX_VAL) ;
        assign cur_mem_nxt_idle_en      = cur_state_cnt_mem_en   &
                                          fifo_rest_en           & 
                                          cur_mem_nxt_idle_en_pre;
 
        assign next_state_idle_en       = cur_idle_nxt_idle_en |
                                          cur_sbu_nxt_idle_en  |
                                          cur_mem_nxt_idle_en  ;
        // next state idle behavior
        assign nxt_idle_prefetch_sbu_cnt_d = oder_en ? SBU_CNT_MAX_VAL : 0;
        assign nxt_idle_prefetch_mem_cnt_d = oder_en ? MEM_CNT_MAX_VAL : 0;

        // next state new_sbu & behavior
        assign cur_idle_nxt_sbu_en      = cur_state_idle_en    & ctrl2pru_start_vld_i;

        assign cur_sbu_nxt_sbu_en_pre   = ~cur_sbu_nxt_idle_en & ~cur_sbu_nxt_mem_en;
        assign cur_sbu_nxt_sbu_en       = cur_state_new_sbu_en & cur_sbu_nxt_sbu_en_pre;

        assign cur_mem_nxt_sbu_en_pre   = oder_en ? (prefetch_sbu_cnt != 0              ) & (prefetch_mem_cnt == 0              ) :
                                                    (prefetch_sbu_cnt != SBU_CNT_MAX_VAL) & (prefetch_mem_cnt == MEM_CNT_MAX_VAL) ;
        assign cur_mem_nxt_sbu_en       = cur_state_cnt_mem_en  & 
                                          fifo_rest_en          &
                                          cur_mem_nxt_sbu_en_pre;

        assign next_state_sbu_en        = cur_idle_nxt_sbu_en |
                                          cur_sbu_nxt_sbu_en  |
                                          cur_mem_nxt_sbu_en  ;

        // next state sbu behavior
        assign cur_idle_nxt_sbu_sbu_cnt   = oder_en ? SBU_CNT_MAX_VAL          : 0                       ;
        assign cur_other_nxt_sbu_sbu_cnt  = oder_en ? (prefetch_sbu_cnt -1'b1) : (prefetch_sbu_cnt +1'b1);

        assign nxt_sbu_prefetch_sbu_cnt_d = {SBU_CNT_W{cur_idle_nxt_sbu_en                    }} & cur_idle_nxt_sbu_sbu_cnt | 
                                            {SBU_CNT_W{cur_sbu_nxt_sbu_en | cur_mem_nxt_sbu_en}} & cur_other_nxt_sbu_sbu_cnt;
        assign nxt_sbu_prefetch_mem_cnt_d = oder_en ? MEM_CNT_MAX_VAL          : 0                       ;

        // next state cnt_mem & behavior
        assign cur_sbu_nxt_mem_en = cur_state_new_sbu_en & sbu2pru_rd_vld_i & sbu2pru_rd_data_i;

        assign cur_mem_nxt_mem_en_pre = oder_en ? (prefetch_mem_cnt != 0              ) :
                                                  (prefetch_mem_cnt != MEM_CNT_MAX_VAL) ;
        assign cur_mem_nxt_mem_en     = cur_state_cnt_mem_en   & 
                                        fifo_rest_en           & // logic have redundancy for readability, actually，cur_state_cnt_mem_en is not need
                                        cur_mem_nxt_mem_en_pre ;

        assign next_state_mem_en      = cur_sbu_nxt_mem_en  |
                                        cur_mem_nxt_mem_en  ;    

        // next state cnt_mem behavior
        assign nxt_mem_prefetch_sbu_cnt_d = prefetch_sbu_cnt;
        assign nxt_mem_prefetch_mem_cnt_d = fifo_rest_en ? 
                                            (oder_en ? (prefetch_mem_cnt - 1) : (prefetch_mem_cnt + 1)):
                                            prefetch_mem_cnt;

        assign next_state_upd_en = next_state_idle_en | next_state_sbu_en | next_state_mem_en;
        assign next_state   = {STATE_W{next_state_idle_en}} & IDLE    |
                              {STATE_W{next_state_sbu_en }} & NEW_SBU |
                              {STATE_W{next_state_mem_en }} & CNT_MEM ;

        assign cnt_upd_en = next_state_idle_en | next_state_sbu_en | next_state_mem_en;
        assign prefetch_sbu_cnt_d = {SBU_CNT_W{next_state_idle_en}} & nxt_idle_prefetch_sbu_cnt_d | 
                                    {SBU_CNT_W{next_state_sbu_en }} & nxt_sbu_prefetch_sbu_cnt_d  |
                                    {SBU_CNT_W{next_state_mem_en }} & nxt_mem_prefetch_sbu_cnt_d  ;

        assign prefetch_mem_cnt_d = {MEM_CNT_W{next_state_idle_en}} & nxt_idle_prefetch_mem_cnt_d | 
                                    {MEM_CNT_W{next_state_sbu_en }} & nxt_sbu_prefetch_mem_cnt_d  |
                                    {MEM_CNT_W{next_state_mem_en }} & nxt_mem_prefetch_mem_cnt_d  ;
                           


        CBB_REGE #(.WIDTH(STATE_W   ),.INIT_VAL(IDLE)) U_REG_PRU_STATE (.clk(clk),.rst(rst),.en(next_state_upd_en),.reg_d(next_state),.reg_q(prefetch_state));
        CBB_REGE #(.WIDTH(SBU_CNT_W ),.INIT_VAL(0   )) U_REG_SBU_CNT   (.clk(clk),.rst(rst),.en(cnt_upd_en),.reg_d(prefetch_sbu_cnt_d),.reg_q(prefetch_sbu_cnt));    
        CBB_REGE #(.WIDTH(MEM_CNT_W ),.INIT_VAL(0   )) U_REG_MEM_CNT   (.clk(clk),.rst(rst),.en(cnt_upd_en),.reg_d(prefetch_mem_cnt_d),.reg_q(prefetch_mem_cnt)); 

    end
    else begin: GEN_NO_PREFETCH_FSM
    
        wire                                       pru2cnt_rd_en             ;
        wire                                       cur_npstate_idle_en       ;
        wire                                       cur_npstate_cnt_mem_en    ;
        wire                                       cur_npidle_nxt_npidle_en  ;
        wire                                       cur_npmem_nxt_npidle_en   ;
        wire                                       nxt_npidle_en             ;
        wire [NPREFETCH_MEM_CNT_W            -1:0] nxt_npidle_mem_cnt_d      ;
        wire [NPREFETCH_MEM_CNT_W            -1:0] npprefetch_mem_cnt        ;
        wire                                       cur_npidle_nxt_npmem_en   ;
        wire                                       cur_npmem_nxt_npmem_en    ;
        wire                                       nxt_npmem_en              ;
        wire [NPREFETCH_MEM_CNT_W            -1:0] nxt_npmem_mem_cnt_d       ;
        wire [NPREFETCH_STATE_W              -1:0] next_npstate_d            ;
        wire [NPREFETCH_STATE_W              -1:0] nprefetch_state           ;
        wire                                       np_mem_cnt_upd_en         ;
        wire [NPREFETCH_MEM_CNT_W            -1:0] nprefetch_mem_cnt_d       ;
        wire [NPREFETCH_MEM_CNT_W            -1:0] nprefetch_mem_cnt         ;

        // input & output logic
        assign pru2sbu_rd_vld_o        = 0;
        assign pru2sbu_rd_addr_o       = 0;

        assign pru2cnt_rd_vld_o        = cur_npstate_cnt_mem_en &
                                         pru2cnt_rd_en          ;
        assign pru2cnt_rd_addr_o       = npprefetch_mem_cnt     ;

        assign pru_fsm_done_vld_o      = cur_npmem_nxt_npidle_en ;        

        // no_prefetch fsm
        assign pru2cnt_rd_en = ~pru_reg_cnt_rd_data_vld & ~cnt2pru_rd_1f_vld_i & ~cnt2pru_rd_vld_i;
        
        assign cur_npstate_idle_en    = nprefetch_state == NPREFETCH_IDLE    ;
        assign cur_npstate_cnt_mem_en = nprefetch_state == NPREFETCH_CNT_MEM ;

        // nxt state idle & behavior
        assign cur_npidle_nxt_npidle_en = cur_npstate_idle_en & ~ctrl2pru_start_vld_i;
        assign cur_npmem_nxt_npidle_en  = cur_npstate_cnt_mem_en  &
                                          pru2cnt_rd_en           &
                                         (nprefetch_mem_cnt == 0) ;

        assign nxt_npidle_en            = cur_npidle_nxt_npidle_en | cur_npmem_nxt_npidle_en;
        
        assign nxt_npidle_mem_cnt_d     = NPREFETCH_MEM_CNT_MAX_VAL;

        // nxt state mem & behavior
        assign cur_npidle_nxt_npmem_en  = cur_npstate_idle_en    & ctrl2pru_start_vld_i;
        assign cur_npmem_nxt_npmem_en   = cur_npstate_cnt_mem_en & (nprefetch_mem_cnt !=0);

        assign nxt_npmem_en             = cur_npidle_nxt_npmem_en | cur_npmem_nxt_npmem_en;
        
        assign nxt_npmem_mem_cnt_d      = pru2cnt_rd_en ? (nprefetch_mem_cnt - 1) :
                                                           npprefetch_mem_cnt     ;

        // regs
        assign next_npstate_d           = {NPREFETCH_STATE_W{nxt_npidle_en}} & NPREFETCH_IDLE    |
                                          {NPREFETCH_STATE_W{nxt_npmem_en }} & NPREFETCH_CNT_MEM ;

        assign np_mem_cnt_upd_en        = nxt_npidle_en | nxt_npmem_en;
        
        assign nprefetch_mem_cnt_d      = {NPREFETCH_MEM_CNT_W{nxt_npidle_en}} & nxt_npidle_mem_cnt_d | 
                                          {NPREFETCH_MEM_CNT_W{nxt_npmem_en }} & nxt_npmem_mem_cnt_d  ;

        CBB_REG  #(.WIDTH(NPREFETCH_STATE_W  ),.INIT_VAL(IDLE                     )) U_REG_NP_STATE   (.clk(clk),.rst(rst),.reg_d(next_npstate_d),.reg_q(nprefetch_state));       
        CBB_REGE #(.WIDTH(NPREFETCH_MEM_CNT_W),.INIT_VAL(NPREFETCH_MEM_CNT_MAX_VAL)) U_REG_NP_MEM_CNT (.clk(clk),.rst(rst),.en(cnt_upd_en),.reg_d(nprefetch_mem_cnt_d),.reg_q(nprefetch_mem_cnt)); 
    end


endgenerate

endmodule