

module SORT_CTRL
(
    input                                         clk                        ,
    input                                         rst                        ,
  
    input  wire                                   ctrl_vld_i                 ,
    input  wire                                   ctrl_input_done_vld_i      ,

    input  wire                                   cntu2ctrl_wr_done_vld_i    ,
    input  wire                                   pru2ctrl_rd_done_vld_i     ,

    output wire                                   ctrl2pru_start_vld_o

);

parameter IDLE    = 0          ;
parameter WR_DATA = IDLE    + 1;
parameter RD_DATA = WR_DATA + 1;
parameter STATE_W = $clog2(RD_DATA+1);

wire [STATE_W                        -1:0] cur_state             ;
wire [STATE_W                        -1:0] next_state            ;
wire                                       cur_state_idle_en     ;
wire                                       cur_state_wr_data_en  ;
wire                                       cur_state_rd_data_en  ;
wire                                       next_state_idle_en    ;
wire                                       next_state_wr_data_en ;
wire                                       next_state_rd_pre_en  ;
wire                                       next_state_rd_data_en ;
wire                                       input_done_flag       ;
wire                                       next_state_upd_en     ;
wire                                       input_done_flag_upd_en;
// input & output logic
assign ctrl2pru_start_vld_o = next_state_rd_data_en;


// FSM logic
assign cur_state_idle_en    = (cur_state == IDLE   );
assign cur_state_wr_data_en = (cur_state == WR_DATA);
assign cur_state_rd_data_en = (cur_state == RD_DATA);

assign next_state_idle_en    = cur_state_idle_en     & ~ctrl_vld_i            | 
                               cur_state_rd_data_en  & pru2ctrl_rd_done_vld_i ;

assign next_state_wr_data_en = cur_state_idle_en     &  ctrl_vld_i            ;

assign next_state_rd_pre_en  = input_done_flag       & cntu2ctrl_wr_done_vld_i;
assign next_state_rd_data_en = cur_state_wr_data_en  & next_state_rd_pre_en   ;

assign next_state_upd_en = next_state_idle_en | next_state_wr_data_en | next_state_rd_data_en;
assign next_state  = {STATE_W{next_state_idle_en   }} & IDLE    |
                     {STATE_W{next_state_wr_data_en}} & WR_DATA |
                     {STATE_W{next_state_rd_data_en}} & RD_DATA ;

assign input_done_flag_upd_en = next_state_rd_pre_en | ctrl_input_done_vld_i;

CBB_REGE #(.WIDTH(STATE_W ),.INIT_VAL(IDLE)) U_REG_STATE           (.clk(clk),.rst(rst),.en(next_state_upd_en     ),.reg_d(next_state),.reg_q(cur_state));
CBB_REGE #(.WIDTH(1       ),.INIT_VAL(IDLE)) U_REG_INPUT_DONE_FLAG (.clk(clk),.rst(rst),.en(input_done_flag_upd_en),.reg_d(ctrl_input_done_vld_i),.reg_q(input_done_flag));

endmodule