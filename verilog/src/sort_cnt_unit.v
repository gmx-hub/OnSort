

module SORT_CNT_UNIT #( 
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM        ,
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM         ,
                  parameter  SORT_FUC_REPEAT_NUM      = `SORT_FUC_REPEAT_NUM     ,
                  parameter  SORT_FUC_REG_EN          = `SORT_FUC_REG_EN         ,

                  parameter  SORT_FUC_BK_DEPTH_W      = $clog2(SORT_FUC_BK_NUM),
                  parameter  SORT_FUC_CNT_MEM_W       = $clog2(SORT_FUC_REPEAT_NUM),
                  parameter  MEM_DATA_W               = SORT_FUC_CNT_MEM_W * SORT_FUC_BK_NUM,
                  parameter  SORT_FUC_CNT_MEM_DEPTH   = (SORT_FUC_MAX_NUM / SORT_FUC_BK_NUM),
                  parameter  SORT_FUC_CNT_MEM_DEPTH_W = $clog2(SORT_FUC_CNT_MEM_DEPTH))
(
    input                                         clk                        ,
    input                                         rst                        ,  
    // AGU
    input  wire                                   agu2cnt_vld_i              ,
    input  wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] agu2cnt_addr_i             , 
    input  wire [SORT_FUC_BK_DEPTH_W        -1:0] agu2cnt_bankid_i           ,
    // PRU
    input  wire                                   pru2cnt_rd_vld_i           ,
    input  wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] pru2cnt_rd_addr_i          ,
    // TO PRU
    output wire                                   cnt2pru_rd_1f_vld_o        ,
    output wire                                   cnt2pru_rd_vld_o           ,
    output wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] cnt2pru_rd_addr_o          ,
    output wire [MEM_DATA_W                 -1:0] cnt2pru_rd_data_o          ,
    //TO CTRL
    output wire                                   cntu2ctrl_wr_done_vld_o    
);


wire                                       cnt_mem_rd_1f_vld     ; 
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt_mem_rd_1f_addr    ; 
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_mem_rd_1f_bkid    ; 
wire                                       cnt_pru_rd_1f_vld     ;
wire [MEM_DATA_W                     -1:0] cnt_mem_rd_1f_data    ; 

wire                                       cnt_mem_rd_2f_vld     ; 
wire [MEM_DATA_W                     -1:0] cnt_mem_rd_2f_data    ; 
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt_mem_rd_2f_addr    ; 
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_mem_rd_2f_bkid    ; 
wire                                       cnt_pru_rd_2f_vld     ; 

wire                                       cnt_mem_rd_3f_vld     ;
wire [MEM_DATA_W                     -1:0] cnt_mem_rd_3f_data    ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt_mem_rd_3f_addr    ;
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_mem_rd_3f_bkid    ;

wire                                       cnt_mem_rd_vld        ;
wire [SORT_FUC_BK_NUM                -1:0] cnt_mem_rd_vld_ext    ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt_mem_rd_addr       ;
wire [SORT_FUC_BK_DEPTH_W            -1:0] cnt_mem_rd_bkid       ;
wire                                       agu_wr_vld            ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] agu_wr_addr           ; 
wire [MEM_DATA_W                     -1:0] agu_wr_data           ; 
wire                                       pru_clr_vld           ; 
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] pru_clr_addr          ; 
wire [MEM_DATA_W                     -1:0] pru_clr_data          ; 
wire [SORT_FUC_BK_NUM                -1:0] cnt_mem_wr_vld        ; 
wire [SORT_FUC_BK_NUM                -1:0] cnt_mem_wr_clr_vld    ;
wire [SORT_FUC_CNT_MEM_DEPTH_W       -1:0] cnt_mem_wr_addr       ;  
wire [MEM_DATA_W                     -1:0] cnt_mem_wr_data       ;  

wire                                       addr_same_1f_en       ;
wire                                       addr_same_1f_vld      ;
wire                                       cnt_addr_same_2f_en   ;
wire                                       cnt_addr_same_2f_vld  ;
wire                                       cnt_addr_same_3f_en   ;
wire                                       cnt_addr_same_3f_vld  ;

wire                                       cnt_mem_rd_3f_vld_d   ;
wire [MEM_DATA_W                     -1:0] cnt_mem_rd_2f_data_d  ; 
wire [MEM_DATA_W                     -1:0] cnt_mem_rd_3f_data_d  ; 
wire [MEM_DATA_W                     -1:0] cnt_wr_mem_data       ; 

wire [SORT_FUC_BK_NUM                -1:0] addr_same_cnt         ;

wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_rd_1f_bk_data     [SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_rd_2f_bk_data     [SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_rd_3f_bk_data     [SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_rd_2f_bk_data_d   [SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_rd_3f_bk_data_d   [SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_wr_mem_bk_data_pre[SORT_FUC_BK_NUM             -1:0];
wire [SORT_FUC_CNT_MEM_W             -1:0] cnt_wr_mem_bk_data    [SORT_FUC_BK_NUM             -1:0];

genvar i;

// submodule

SORT_CNT_MEM #(
           .DATA_WIDTH              (SORT_FUC_CNT_MEM_W           ),   
           .ADDR_WIDTH              (SORT_FUC_CNT_MEM_DEPTH_W     ),  
           .NUM_BANKS               (SORT_FUC_BK_NUM              ),
           .REG_EN                  (SORT_FUC_REG_EN              ))
U_SORT_CNT_MEM
(
    .clk                            (clk                          ),
    .rst                            (rst                          ),
    .wr_en                          (cnt_mem_wr_vld               ),          
    .rd_en                          (cnt_mem_rd_vld_ext           ), 
    .wr_addr                        (cnt_mem_wr_addr              ),  
    .rd_addr                        (cnt_mem_rd_addr              ),  
    .data_in                        (cnt_mem_wr_data              ), 
    .data_out                       (cnt_mem_rd_1f_data           ) 
);

// output
assign cntu2ctrl_wr_done_vld_o = ~agu2cnt_vld_i & ~cnt_mem_rd_1f_vld & ~cnt_mem_rd_2f_vld & ~cnt_mem_rd_3f_vld;

assign cnt2pru_rd_1f_vld_o     = cnt_pru_rd_1f_vld ;
assign cnt2pru_rd_vld_o        = cnt_pru_rd_2f_vld ;
assign cnt2pru_rd_addr_o       = cnt_mem_rd_2f_addr;
assign cnt2pru_rd_data_o       = cnt_mem_rd_2f_data;


// check agu_addr and cnt_pipe_addr
assign addr_same_1f_en  = (agu2cnt_addr_i == cnt_mem_rd_1f_addr);
assign addr_same_1f_vld =  agu2cnt_vld_i & cnt_mem_rd_1f_vld & addr_same_1f_en;

assign addr_same_2f_en  = (agu2cnt_addr_i == cnt_mem_rd_2f_addr);
assign addr_same_2f_vld = agu2cnt_vld_i & cnt_mem_rd_2f_vld & addr_same_2f_en;

assign addr_same_3f_en  = (agu2cnt_addr_i == cnt_mem_rd_3f_addr);
assign addr_same_3f_vld = agu2cnt_vld_i & cnt_mem_rd_3f_vld & addr_same_3f_en;

// memory or reg rd
assign cnt_mem_rd_vld     = pru2cnt_rd_vld_i |  (agu2cnt_vld_i & ~addr_same_1f_vld & ~addr_same_2f_vld & ~addr_same_3f_vld);
assign cnt_mem_rd_vld_ext = {SORT_FUC_BK_NUM{cnt_mem_rd_vld}};
assign cnt_mem_rd_addr    = pru2cnt_rd_vld_i ? pru2cnt_rd_addr_i           : agu2cnt_addr_i  ;
assign cnt_mem_rd_bkid    = pru2cnt_rd_vld_i ? {SORT_FUC_BK_DEPTH_W{1'b0}} : agu2cnt_bankid_i;

// memory or reg wr
assign agu_wr_vld  = cnt_mem_rd_3f_vld;
assign agu_wr_addr = cnt_mem_rd_3f_addr;
assign agu_wr_data = cnt_wr_mem_data;

assign pru_clr_vld  = cnt_pru_rd_2f_vld ;
assign pru_clr_addr = cnt_mem_rd_2f_addr;
assign pru_clr_data = {MEM_DATA_W{1'b0}};


assign cnt_mem_wr_clr_vld = {SORT_FUC_BK_NUM{cnt_pru_rd_2f_vld}};

assign cnt_mem_wr_vld  = {SORT_FUC_BK_NUM{agu_wr_vld}} | cnt_mem_wr_clr_vld;
assign cnt_mem_wr_addr = {SORT_FUC_CNT_MEM_DEPTH_W{agu_wr_vld }} & agu_wr_addr  | 
                         {SORT_FUC_CNT_MEM_DEPTH_W{pru_clr_vld}} & pru_clr_addr ;
assign cnt_mem_wr_data = {MEM_DATA_W{agu_wr_vld }} & agu_wr_data  | 
                         {MEM_DATA_W{pru_clr_vld}} & pru_clr_data ;


//regs
//special logic

generate
    for (i=0; i<SORT_FUC_BK_NUM; i=i+1) begin: GEN_CNTU_RD_CNT
        // generate bk data
        assign cnt_rd_1f_bk_data     [i] = cnt_mem_rd_1f_data[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W];
        assign cnt_rd_2f_bk_data     [i] = cnt_mem_rd_2f_data[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W];
        assign cnt_rd_3f_bk_data     [i] = cnt_mem_rd_3f_data[(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W];

        assign addr_same_cnt         [i] = (agu2cnt_bankid_i == i) ? 1'b1 : 1'b0;
        assign cnt_rd_2f_bk_data_d   [i] = addr_same_1f_vld ? (cnt_rd_1f_bk_data[i] + addr_same_cnt[i]) : cnt_rd_1f_bk_data[i];
        assign cnt_rd_3f_bk_data_d   [i] = addr_same_2f_vld ? (cnt_rd_2f_bk_data[i] + addr_same_cnt[i]) : cnt_rd_2f_bk_data[i];
        assign cnt_wr_mem_bk_data_pre[i] = addr_same_3f_vld ? (cnt_rd_3f_bk_data[i] + addr_same_cnt[i]) : cnt_rd_3f_bk_data[i];

        assign cnt_wr_mem_bk_data    [i] = (cnt_mem_rd_3f_bkid == i) ? (cnt_wr_mem_bk_data_pre[i] + 1'b1) : cnt_wr_mem_bk_data_pre[i];
        
        // splice bk data
        assign cnt_mem_rd_2f_data_d [(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W] = cnt_rd_2f_bk_data_d[i];
        assign cnt_mem_rd_3f_data_d [(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W] = cnt_rd_3f_bk_data_d[i];

        assign cnt_wr_mem_data  [(i+1)*SORT_FUC_CNT_MEM_W-1 : i*SORT_FUC_CNT_MEM_W] = cnt_wr_mem_bk_data[i];
    end
endgenerate

assign cnt_mem_rd_3f_vld_d = cnt_mem_rd_2f_vld & ~cnt_pru_rd_2f_vld;

// 1f
CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_PRU_RD_1F_VLD (.clk(clk),.rst(rst),.reg_d(pru2cnt_rd_vld_i),.reg_q(cnt_pru_rd_1f_vld));
CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_CNT_RD_1F_VLD (.clk(clk),.rst(rst),.reg_d(cnt_mem_rd_vld  ),.reg_q(cnt_mem_rd_1f_vld));

CBB_REGE #(.WIDTH(SORT_FUC_CNT_MEM_DEPTH_W),.INIT_VAL(0)) U_REG_CNT_RD_1F_ADDR (.clk(clk),.rst(rst),.en(cnt_mem_rd_vld),.reg_d(cnt_mem_rd_addr),.reg_q(cnt_mem_rd_1f_addr));
CBB_REGE #(.WIDTH(SORT_FUC_BK_DEPTH_W     ),.INIT_VAL(0)) U_REG_CNT_RD_1F_BKID (.clk(clk),.rst(rst),.en(cnt_mem_rd_vld),.reg_d(cnt_mem_rd_bkid),.reg_q(cnt_mem_rd_1f_bkid));

// 2f
CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_PRU_RD_2F_VLD (.clk(clk),.rst(rst),.reg_d(cnt_pru_rd_1f_vld),.reg_q(cnt_pru_rd_2f_vld));
CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_CNT_RD_2F_VLD (.clk(clk),.rst(rst),.reg_d(cnt_mem_rd_1f_vld),.reg_q(cnt_mem_rd_2f_vld));

CBB_REGE #(.WIDTH(SORT_FUC_CNT_MEM_DEPTH_W),.INIT_VAL(0)) U_REG_CNT_RD_2F_ADDR (.clk(clk),.rst(rst),.en(cnt_mem_rd_1f_vld),.reg_d(cnt_mem_rd_1f_addr  ),.reg_q(cnt_mem_rd_2f_addr));
CBB_REGE #(.WIDTH(SORT_FUC_BK_DEPTH_W     ),.INIT_VAL(0)) U_REG_CNT_RD_2F_BKID (.clk(clk),.rst(rst),.en(cnt_mem_rd_1f_vld),.reg_d(cnt_mem_rd_1f_bkid  ),.reg_q(cnt_mem_rd_2f_bkid));
CBB_REGE #(.WIDTH(MEM_DATA_W              ),.INIT_VAL(0)) U_REG_CNT_RD_2F_DATA (.clk(clk),.rst(rst),.en(cnt_mem_rd_1f_vld),.reg_d(cnt_mem_rd_2f_data_d),.reg_q(cnt_mem_rd_2f_data));

// 3f 
CBB_REG  #(.WIDTH(1),.INIT_VAL(0)) U_REG_CNT_RD_3F_VLD (.clk(clk),.rst(rst),.reg_d(cnt_mem_rd_3f_vld_d),.reg_q(cnt_mem_rd_3f_vld));

CBB_REGE #(.WIDTH(SORT_FUC_CNT_MEM_DEPTH_W),.INIT_VAL(0)) U_REG_CNT_RD_3F_ADDR (.clk(clk),.rst(rst),.en(cnt_mem_rd_3f_vld_d),.reg_d(cnt_mem_rd_2f_addr  ),.reg_q(cnt_mem_rd_3f_addr));
CBB_REGE #(.WIDTH(SORT_FUC_BK_DEPTH_W     ),.INIT_VAL(0)) U_REG_CNT_RD_3F_BKID (.clk(clk),.rst(rst),.en(cnt_mem_rd_3f_vld_d),.reg_d(cnt_mem_rd_2f_bkid  ),.reg_q(cnt_mem_rd_3f_bkid));
CBB_REGE #(.WIDTH(MEM_DATA_W              ),.INIT_VAL(0)) U_REG_CNT_RD_3F_DATA (.clk(clk),.rst(rst),.en(cnt_mem_rd_3f_vld_d),.reg_d(cnt_mem_rd_3f_data_d),.reg_q(cnt_mem_rd_3f_data));


endmodule