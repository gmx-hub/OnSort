

module SORT_CTRL
(
    input                                         clk                        ,
    input                                         rst                        ,
  
    input  wire                                   ctrl_vld_i                 ,
    input  wire                                   ctrl_input_done_vld_i      ,

    input  wire                                   cntu2ctrl_wr_done_vld_i    ,
    input  wire                                   pru2ctrl_rd_done_vld_i     ,

    output wire                                   ctrl2pru_start_vld_o       ,
    output wire                                   ctrl2input_rdy_o           , 
    output wire                                   ctrl_rd_sel_o              ,
    output wire                                   ctrl_wr_sel_o
);
wire                                       cnt_mem_rd_1f_vld                 ; 

wire                                       wr_ptr_upd_en                     ;
wire                                       wr_ptr_d                          ;
wire                                       wr_ptr                            ;
wire                                       rd_ptr_upd_en                     ;
wire                                       rd_ptr_d                          ;
wire                                       rd_ptr                            ; 
wire                                       cnt_wr_ptr_upd_en                 ;
wire                                       cnt_wr_ptr_d                      ;
wire                                       cnt_wr_ptr                        ;
wire                                       tsk0_vld_set_en                   ;
wire                                       tsk0_vld_clr_en                   ;
wire                                       tsk0_vld_upd_en                   ;
wire                                       tsk0_vld_d                        ;
wire                                       tsk0_vld                          ;
wire                                       tsk1_vld_set_en                   ; 
wire                                       tsk1_vld_clr_en                   ; 
wire                                       tsk1_vld_upd_en                   ; 
wire                                       tsk1_vld_d                        ;
wire                                       tsk1_vld                          ;
wire                                       tsk0_data_in_done_flag_set_en     ;
wire                                       tsk0_data_in_done_flag_clr_en     ;
wire                                       tsk0_data_in_done_flag_upd_en     ;
wire                                       tsk0_data_in_done_flag_d          ;
wire                                       tsk0_data_in_done_flag            ;
wire                                       tsk1_data_in_done_flag_set_en     ;
wire                                       tsk1_data_in_done_flag_clr_en     ;
wire                                       tsk1_data_in_done_flag_upd_en     ;
wire                                       tsk1_data_in_done_flag_d          ;
wire                                       tsk1_data_in_done_flag            ;
wire                                       tsk0_wr_done_flag_set_en          ;
wire                                       tsk0_wr_done_flag_clr_en          ;
wire                                       tsk0_wr_done_flag_upd_en          ;
wire                                       tsk0_wr_done_flag_d               ;
wire                                       tsk0_wr_done_flag                 ;
wire                                       tsk1_wr_done_flag_set_en          ;
wire                                       tsk1_wr_done_flag_clr_en          ;
wire                                       tsk1_wr_done_flag_upd_en          ;
wire                                       tsk1_wr_done_flag_d               ;
wire                                       tsk1_wr_done_flag                 ;
wire                                       tsk0_rd_start_flag_upd_en         ; 
wire                                       tsk0_rd_start_flag_d              ; 
wire                                       tsk0_rd_start_flag                ; 
wire                                       tsk1_rd_start_flag_upd_en         ; 
wire                                       tsk1_rd_start_flag_d              ; 
wire                                       tsk1_rd_start_flag                ;


// input & output logic
assign ctrl2input_rdy_o = ~ ( tsk0_vld & (tsk0_data_in_done_flag | ctrl_input_done_vld_i) &
                              tsk1_vld & (tsk1_data_in_done_flag | ctrl_input_done_vld_i) );


assign ctrl2pru_start_vld_o = ((rd_ptr==0) & tsk0_vld & tsk0_data_in_done_flag & tsk0_wr_done_flag & ~tsk0_rd_start_flag) |
                              ((rd_ptr==1) & tsk1_vld & tsk1_data_in_done_flag & tsk1_wr_done_flag & ~tsk1_rd_start_flag) ;

assign ctrl_rd_sel_o = rd_ptr;
assign ctrl_wr_sel_o = wr_ptr;

// logic
assign wr_ptr_upd_en = ctrl_input_done_vld_i;
assign wr_ptr_d      = ~wr_ptr;

assign rd_ptr_upd_en = pru2ctrl_rd_done_vld_i;
assign rd_ptr_d      = ~rd_ptr;

assign cnt_wr_ptr_upd_en = cntu2ctrl_wr_done_vld_i;
assign cnt_wr_ptr_d      = ~cnt_wr_ptr;

assign tsk0_vld_set_en = ~tsk0_vld & ctrl_vld_i & ~wr_ptr;
assign tsk0_vld_clr_en = rd_ptr_upd_en & ~rd_ptr;
assign tsk0_vld_upd_en = tsk0_vld_set_en | tsk0_vld_clr_en;
assign tsk0_vld_d      = tsk0_vld_set_en ;

assign tsk1_vld_set_en = ~tsk1_vld & ctrl_vld_i & wr_ptr;
assign tsk1_vld_clr_en = rd_ptr_upd_en & rd_ptr;
assign tsk1_vld_upd_en = tsk1_vld_set_en | tsk1_vld_clr_en;
assign tsk1_vld_d      = tsk1_vld_set_en;

assign tsk0_data_in_done_flag_set_en = ctrl_input_done_vld_i & ~wr_ptr;
assign tsk0_data_in_done_flag_clr_en = tsk0_vld_clr_en;
assign tsk0_data_in_done_flag_upd_en = tsk0_data_in_done_flag_set_en | tsk0_data_in_done_flag_clr_en;
assign tsk0_data_in_done_flag_d      = tsk0_data_in_done_flag_set_en;

assign tsk1_data_in_done_flag_set_en = ctrl_input_done_vld_i & wr_ptr;
assign tsk1_data_in_done_flag_clr_en = tsk1_vld_clr_en;
assign tsk1_data_in_done_flag_upd_en = tsk1_data_in_done_flag_set_en | tsk1_data_in_done_flag_clr_en;
assign tsk1_data_in_done_flag_d      = tsk1_data_in_done_flag_set_en;

assign tsk0_wr_done_flag_set_en = tsk0_data_in_done_flag & cntu2ctrl_wr_done_vld_i & ~cnt_wr_ptr;
assign tsk0_wr_done_flag_clr_en = ctrl2pru_start_vld_o & ~rd_ptr;
assign tsk0_wr_done_flag_upd_en = tsk0_wr_done_flag_set_en | tsk0_wr_done_flag_clr_en;
assign tsk0_wr_done_flag_d      = tsk0_wr_done_flag_set_en;

assign tsk1_wr_done_flag_set_en = tsk1_data_in_done_flag & cntu2ctrl_wr_done_vld_i & cnt_wr_ptr;
assign tsk1_wr_done_flag_clr_en = ctrl2pru_start_vld_o & rd_ptr;
assign tsk1_wr_done_flag_upd_en = tsk1_wr_done_flag_set_en | tsk1_wr_done_flag_clr_en;
assign tsk1_wr_done_flag_d      = tsk1_wr_done_flag_set_en;

assign tsk0_rd_start_flag_upd_en = (ctrl2pru_start_vld_o & ~rd_ptr) | tsk0_vld_clr_en;
assign tsk0_rd_start_flag_d      = (ctrl2pru_start_vld_o & ~rd_ptr) ;

assign tsk1_rd_start_flag_upd_en = (ctrl2pru_start_vld_o &  rd_ptr) | tsk1_vld_clr_en;
assign tsk1_rd_start_flag_d      = (ctrl2pru_start_vld_o &  rd_ptr) ;


CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_RD_PTR    (.clk(clk),.rst(rst),.en(rd_ptr_upd_en    ),.reg_d(rd_ptr_d    ),.reg_q(rd_ptr    ));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_WR_PTR    (.clk(clk),.rst(rst),.en(wr_ptr_upd_en    ),.reg_d(wr_ptr_d    ),.reg_q(wr_ptr    ));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_CNT_WRPTR (.clk(clk),.rst(rst),.en(cnt_wr_ptr_upd_en),.reg_d(cnt_wr_ptr_d),.reg_q(cnt_wr_ptr));

CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK0_VLD  (.clk(clk),.rst(rst),.en(tsk0_vld_upd_en),.reg_d(tsk0_vld_d),.reg_q(tsk0_vld));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK1_VLD  (.clk(clk),.rst(rst),.en(tsk1_vld_upd_en),.reg_d(tsk1_vld_d),.reg_q(tsk1_vld));

CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK0_IN_DONE_FLAG (.clk(clk),.rst(rst),.en(tsk0_data_in_done_flag_upd_en),.reg_d(tsk0_data_in_done_flag_d),.reg_q(tsk0_data_in_done_flag));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK1_IN_DONE_FLAG (.clk(clk),.rst(rst),.en(tsk1_data_in_done_flag_upd_en),.reg_d(tsk1_data_in_done_flag_d),.reg_q(tsk1_data_in_done_flag));


CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK0_WR_DONE_FLAG (.clk(clk),.rst(rst),.en(tsk0_wr_done_flag_upd_en),.reg_d(tsk0_wr_done_flag_d),.reg_q(tsk0_wr_done_flag));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK1_WR_DONE_FLAG (.clk(clk),.rst(rst),.en(tsk1_wr_done_flag_upd_en),.reg_d(tsk1_wr_done_flag_d),.reg_q(tsk1_wr_done_flag));

CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK0_RDSTAR_FLAG (.clk(clk),.rst(rst),.en(tsk0_rd_start_flag_upd_en),.reg_d(tsk0_rd_start_flag_d),.reg_q(tsk0_rd_start_flag));
CBB_REGE #(.WIDTH(1),.INIT_VAL(0)) U_REG_TSK1_RDSTAR_FLAG (.clk(clk),.rst(rst),.en(tsk1_rd_start_flag_upd_en),.reg_d(tsk1_rd_start_flag_d),.reg_q(tsk1_rd_start_flag));


endmodule