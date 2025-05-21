import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from simulator_common.cbb.reg import reg

import pdb

## sort_ctrl class simulate the behavior of sort ctrl in hardware

class sort_ctrl:
    def __init__(self):
        ## reg
        self.ctrl_reg_rd_ptr                 = reg(0)
        self.ctrl_reg_wr_ptr                 = reg(0)
        self.ctrl_reg_cnt_wr_ptr             = reg(0)
        self.ctrl_reg_tsk0_vld               = reg(0)
        self.ctrl_reg_tsk0_data_in_done_flag = reg(0)
        self.ctrl_reg_tsk0_data_wr_done_flag = reg(0)
        self.ctrl_reg_tsk0_data_rd_done_flag = reg(0)
        self.ctrl_reg_tsk0_rd_start_flag     = reg(0)
        self.ctrl_reg_tsk1_vld               = reg(0)
        self.ctrl_reg_tsk1_data_in_done_flag = reg(0)
        self.ctrl_reg_tsk1_data_wr_done_flag = reg(0)
        self.ctrl_reg_tsk1_data_rd_done_flag = reg(0)
        self.ctrl_reg_tsk1_rd_start_flag     = reg(0)
        
        self.a = 0

    def sort_ctrl_wr_state_func(self,ctrl_input_done_vld_i):
        
        reg_rd_ptr                 = self.ctrl_reg_rd_ptr                .get_reg_q()
        reg_wr_ptr                 = self.ctrl_reg_wr_ptr                .get_reg_q()
        reg_tsk0_vld               = self.ctrl_reg_tsk0_vld              .get_reg_q()
        reg_tsk0_data_in_done_flag = self.ctrl_reg_tsk0_data_in_done_flag.get_reg_q()
        reg_tsk0_data_wr_done_flag = self.ctrl_reg_tsk0_data_wr_done_flag.get_reg_q()
        reg_tsk0_rd_start_flag     = self.ctrl_reg_tsk0_rd_start_flag    .get_reg_q()
        reg_tsk1_vld               = self.ctrl_reg_tsk1_vld              .get_reg_q()
        reg_tsk1_data_in_done_flag = self.ctrl_reg_tsk1_data_in_done_flag.get_reg_q()
        reg_tsk1_data_wr_done_flag = self.ctrl_reg_tsk1_data_wr_done_flag.get_reg_q()
        reg_tsk1_rd_start_flag     = self.ctrl_reg_tsk1_rd_start_flag    .get_reg_q()

        ctrl2input_rdy_inv =  ( ((reg_tsk0_vld==1) & ((reg_tsk0_data_in_done_flag==1) | (ctrl_input_done_vld_i ==1))) &
                                ((reg_tsk1_vld==1) & ((reg_tsk1_data_in_done_flag==1) | (ctrl_input_done_vld_i ==1))) )
        ctrl2input_rdy     = True if (ctrl2input_rdy_inv==0) else False
        
        ctrl_wr_sel = reg_wr_ptr
        ctrl_rd_sel = reg_rd_ptr

        ctrl2pru_start_vld_o = ((reg_rd_ptr == 0) & (reg_tsk0_vld ==1) & (reg_tsk0_data_in_done_flag ==1) & (reg_tsk0_data_wr_done_flag ==1) & (reg_tsk0_rd_start_flag==0)) | \
                               ((reg_rd_ptr == 1) & (reg_tsk1_vld ==1) & (reg_tsk1_data_in_done_flag ==1) & (reg_tsk1_data_wr_done_flag ==1) & (reg_tsk1_rd_start_flag==0)) 
    
        self.a = self.a+1
        return ctrl2pru_start_vld_o,ctrl2input_rdy,ctrl_rd_sel,ctrl_wr_sel


    def sort_ctrl_upd_state_func(self,
                       ##input 
                       ctrl_vld_i,
                       ctrl_input_done_vld_i,

                       cntu2ctrl_wr_done_vld_i,

                       pru2ctrl_rd_done_vld_i
                       ):

        reg_rd_ptr                 = self.ctrl_reg_rd_ptr                .get_reg_q()
        reg_wr_ptr                 = self.ctrl_reg_wr_ptr                .get_reg_q()
        reg_cnt_wr_ptr             = self.ctrl_reg_cnt_wr_ptr            .get_reg_q()
        reg_tsk0_vld               = self.ctrl_reg_tsk0_vld              .get_reg_q()
        reg_tsk0_data_in_done_flag = self.ctrl_reg_tsk0_data_in_done_flag.get_reg_q()
        reg_tsk0_data_wr_done_flag = self.ctrl_reg_tsk0_data_wr_done_flag.get_reg_q() 
        reg_tsk0_rd_start_flag     = self.ctrl_reg_tsk0_rd_start_flag    .get_reg_q()
        reg_tsk1_vld               = self.ctrl_reg_tsk1_vld              .get_reg_q()
        reg_tsk1_data_in_done_flag = self.ctrl_reg_tsk1_data_in_done_flag.get_reg_q()
        reg_tsk1_data_wr_done_flag = self.ctrl_reg_tsk1_data_wr_done_flag.get_reg_q()
        reg_tsk1_rd_start_flag     = self.ctrl_reg_tsk1_rd_start_flag    .get_reg_q()


        ctrl2pru_start_vld_o = ((reg_rd_ptr == 0) & (reg_tsk0_vld ==1) & (reg_tsk0_data_in_done_flag ==1) & (reg_tsk0_data_wr_done_flag ==1) & (reg_tsk0_rd_start_flag==0)) | \
                               ((reg_rd_ptr == 1) & (reg_tsk1_vld ==1) & (reg_tsk1_data_in_done_flag ==1) & (reg_tsk1_data_wr_done_flag ==1) & (reg_tsk1_rd_start_flag==0)) 

        wr_ptr_upd_en = ctrl_input_done_vld_i
        wr_ptr_d      = 1 if reg_wr_ptr ==0 else 0

        rd_ptr_upd_en = pru2ctrl_rd_done_vld_i
        rd_ptr_d      = 1 if reg_rd_ptr ==0 else 0

        cnt_wr_ptr_upd_en = cntu2ctrl_wr_done_vld_i
        cnt_wr_ptr_d  = 1 if reg_cnt_wr_ptr ==0 else 0

        cur_wr_ptr_0_en = (reg_wr_ptr ==0)
        cur_wr_ptr_1_en = (reg_wr_ptr ==1)
        cur_rd_ptr_0_en = (reg_rd_ptr ==0)
        cur_rd_ptr_1_en = (reg_rd_ptr ==1)        

        tsk0_vld_set_en = (reg_tsk0_vld ==0) & ctrl_vld_i & cur_wr_ptr_0_en
        tsk0_vld_clr_en = (rd_ptr_upd_en ==1) & cur_rd_ptr_0_en
        tsk0_vld_upd_en = tsk0_vld_set_en | tsk0_vld_clr_en
        tsk0_vld_d      = tsk0_vld_set_en

        tsk1_vld_set_en = (reg_tsk1_vld ==0) & ctrl_vld_i & cur_wr_ptr_1_en
        tsk1_vld_clr_en = (rd_ptr_upd_en ==1) & cur_rd_ptr_1_en
        tsk1_vld_upd_en = tsk1_vld_set_en | tsk1_vld_clr_en
        tsk1_vld_d      = tsk1_vld_set_en

        tsk0_data_in_done_flag_set_en = ctrl_input_done_vld_i & cur_wr_ptr_0_en
        tsk0_data_in_done_flag_clr_en = tsk0_vld_clr_en
        tsk0_data_in_done_flag_upd_en = tsk0_data_in_done_flag_set_en | tsk0_data_in_done_flag_clr_en
        tsk0_data_in_done_flag_d      = tsk0_data_in_done_flag_set_en

        tsk1_data_in_done_flag_set_en = ctrl_input_done_vld_i & cur_wr_ptr_1_en
        tsk1_data_in_done_flag_clr_en = tsk1_vld_clr_en
        tsk1_data_in_done_flag_upd_en = tsk1_data_in_done_flag_set_en | tsk1_data_in_done_flag_clr_en
        tsk1_data_in_done_flag_d      = tsk1_data_in_done_flag_set_en

        tsk0_wr_done_flag_set_en = (reg_tsk0_data_in_done_flag==1) & cntu2ctrl_wr_done_vld_i & (reg_cnt_wr_ptr==0)
        tsk0_wr_done_flag_clr_en = ctrl2pru_start_vld_o & (reg_rd_ptr == 0)
        tsk0_wr_done_flag_upd_en = tsk0_wr_done_flag_set_en | tsk0_wr_done_flag_clr_en
        tsk0_wr_done_flag_d      = tsk0_wr_done_flag_set_en

        tsk1_wr_done_flag_set_en = (reg_tsk1_data_in_done_flag==1) & cntu2ctrl_wr_done_vld_i & (reg_cnt_wr_ptr==1)
        tsk1_wr_done_flag_clr_en = ctrl2pru_start_vld_o & (reg_rd_ptr == 1)
        tsk1_wr_done_flag_upd_en = tsk1_wr_done_flag_set_en | tsk1_wr_done_flag_clr_en
        tsk1_wr_done_flag_d      = tsk1_wr_done_flag_set_en


        tsk0_rd_start_flag_upd_en = (ctrl2pru_start_vld_o & ((reg_rd_ptr == 0))) | tsk0_vld_clr_en
        tsk0_rd_start_flag_d      = (ctrl2pru_start_vld_o & ((reg_rd_ptr == 0)))

        tsk1_rd_start_flag_upd_en = (ctrl2pru_start_vld_o & ((reg_rd_ptr == 1))) | tsk1_vld_clr_en
        tsk1_rd_start_flag_d      = (ctrl2pru_start_vld_o & ((reg_rd_ptr == 1)))        
        

        self.ctrl_reg_rd_ptr                .set_reg_d_with_en(rd_ptr_upd_en                ,rd_ptr_d                )
        self.ctrl_reg_wr_ptr                .set_reg_d_with_en(wr_ptr_upd_en                ,wr_ptr_d                )
        self.ctrl_reg_cnt_wr_ptr            .set_reg_d_with_en(cnt_wr_ptr_upd_en            ,cnt_wr_ptr_d            )
        self.ctrl_reg_tsk0_vld              .set_reg_d_with_en(tsk0_vld_upd_en              ,tsk0_vld_d              )
        self.ctrl_reg_tsk0_data_in_done_flag.set_reg_d_with_en(tsk0_data_in_done_flag_upd_en,tsk0_data_in_done_flag_d)
        self.ctrl_reg_tsk0_data_wr_done_flag.set_reg_d_with_en(tsk0_wr_done_flag_upd_en     ,tsk0_wr_done_flag_d     ) 
        self.ctrl_reg_tsk0_rd_start_flag    .set_reg_d_with_en(tsk0_rd_start_flag_upd_en    ,tsk0_rd_start_flag_d    )
        self.ctrl_reg_tsk1_vld              .set_reg_d_with_en(tsk1_vld_upd_en              ,tsk1_vld_d              )
        self.ctrl_reg_tsk1_data_in_done_flag.set_reg_d_with_en(tsk1_data_in_done_flag_upd_en,tsk1_data_in_done_flag_d)
        self.ctrl_reg_tsk1_data_wr_done_flag.set_reg_d_with_en(tsk1_wr_done_flag_upd_en     ,tsk1_wr_done_flag_d     )
        self.ctrl_reg_tsk1_rd_start_flag    .set_reg_d_with_en(tsk1_rd_start_flag_upd_en    ,tsk1_rd_start_flag_d    )