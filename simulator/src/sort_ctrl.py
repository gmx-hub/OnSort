import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

from simulator_common.cbb.reg import reg

## sort_ctrl class simulate the behavior of sort ctrl in hardware

class sort_ctrl:
    def __init__(self):
        ## state
        self.state_rst     = 0
        self.state_wr      = self.state_rst + 1
        self.state_rd      = self.state_wr + 1

        ## reg
        self.ctrl_reg_state             = reg(self.state_rst) 
        self.ctrl_reg_input_done_vld_1f = reg(0)


    def sort_ctrl_wr_state_func(self,
                                cntu2ctrl_wr_done_vld_i):
        
        reg_state             = self.ctrl_reg_state            .get_reg_q() 
        reg_input_done_vld_1f = self.ctrl_reg_input_done_vld_1f.get_reg_q() 

        cur_state_wr_en       = (reg_state == self.state_wr)

        next_state_rd_en =0
        if (cur_state_wr_en):
            next_state_rd_en = (reg_input_done_vld_1f ==1) & (cntu2ctrl_wr_done_vld_i == 1)

        ctrl2pru_start_vld_o = next_state_rd_en

        return ctrl2pru_start_vld_o


    def sort_ctrl_upd_state_func(self,
                       ##input 
                       ctrl_vld_i,
                       ctrl_input_done_vld_i,
                       cntu2ctrl_wr_done_vld_i,

                       pru2ctrl_rd_done_vld_i
                       ):
        
        reg_state             = self.ctrl_reg_state            .get_reg_q() 
        reg_input_done_vld_1f = self.ctrl_reg_input_done_vld_1f.get_reg_q() 

        cur_state_rst_en      = (reg_state == self.state_rst)
        cur_state_wr_en       = (reg_state == self.state_wr)
        cur_state_rd_en       = (reg_state == self.state_rd)
        
        next_state_rd_en      = 0

        if (cur_state_rst_en):
            next_state  = self.state_wr if ctrl_vld_i else self.state_rst

        if (cur_state_wr_en):
            next_state_rd_en = (reg_input_done_vld_1f ==1) & (cntu2ctrl_wr_done_vld_i == 1)
            next_state  = self.state_rd if next_state_rd_en else self.state_wr

        if (cur_state_rd_en):
            next_state  = self.state_rst if pru2ctrl_rd_done_vld_i else self.state_rd

        self.ctrl_reg_state            .set_reg_d(next_state) 
        self.ctrl_reg_input_done_vld_1f.set_reg_d_with_en(((ctrl_input_done_vld_i==1) | (cntu2ctrl_wr_done_vld_i==1)), ctrl_input_done_vld_i)

    