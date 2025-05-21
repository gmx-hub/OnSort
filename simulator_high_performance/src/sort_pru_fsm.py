import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_high_performance.src.sort_sbu         import sort_sbu

from simulator_common.cbb.reg              import reg
from simulator_high_performance.top.const  import const
from simulator_common.utils.logging_config import logging_config

import simulator_common.utils.utils as utils

## pru unit fsm class simulate the behavior of prefetch read unit fsm module in hardware
class sort_pru_fsm:
    def __init__(self):
        self.logger = logging_config(__name__)

        ## define submodule
        self.sbu       = sort_sbu()

        ## prefetch fucntion
        ## parameter
        self.para_mem_cnt_max_val = const.SORT_FUC_SBU_TILE_CNT_MAX_NUM -1
        self.para_sbu_cnt_max_val = const.SORT_PERF_SBU_NUM -1
        ## state 
        self.state_rst     = 0
        self.state_new_sbu = self.state_rst + 1
        self.state_cnt_mem = self.state_new_sbu + 1
        ## reg
        self.pru_reg_prefetch_state   = reg(self.state_rst)
        self.pru_reg_prefetch_sbu_cnt = reg(self.para_sbu_cnt_max_val)
        self.pru_reg_prefetch_mem_cnt = reg(self.para_mem_cnt_max_val)

        ## without prefetch function
        ## parameter
        self.para_nprefetch_mem_cnt_max_val = const.SORT_FUC_CNT_MEM_DEPTH-1
        ## state
        self.nprefetch_state_rst     = 0
        self.nprefetch_state_cnt_mem = self.nprefetch_state_rst + 1
        ## reg
        self.pru_reg_nprefetch_state   = reg(self.nprefetch_state_rst)
        self.pru_reg_nprefetch_mem_cnt = reg(self.para_nprefetch_mem_cnt_max_val)


    def pru_fsm_prefetch_func(self,
                ## input 
                ## from ctrl
                ctrl_wr_sel,
                ctrl_rd_sel,
                ## from control
                ctrl2pru_start_vld_i, 
                ctrl2pru_config_oder_en_i,

                ## from agu
                agu2pru_sbu_wr_vld_i,
                agu2pru_sbu_wr_addr_i,

                cnt2pru_rd_1f_vld_i, ## 1f
                cnt2pru_rd_vld_i,  ## 2f

                ## from fifo
                reg_fifo_cnt
                ):
        reg_prefetch_state    = self.pru_reg_prefetch_state.get_reg_q()  
        reg_prefetch_sbu_cnt  = self.pru_reg_prefetch_sbu_cnt.get_reg_q()
        reg_prefetch_mem_cnt  = self.pru_reg_prefetch_mem_cnt.get_reg_q()

        pru_fsm_done_vld      = 0
        pru2cnt_rd_vld_o      = 0
        pru2cnt_rd_addr_o     = 0

        if((cnt2pru_rd_1f_vld_i==1) & (cnt2pru_rd_vld_i==1)):
            fifo_rest_en     = reg_fifo_cnt <= const.SORT_PERF_PREFETCH_DEPTH - 3*const.SORT_FUC_BK_NUM 
        elif((cnt2pru_rd_1f_vld_i ==1) | (cnt2pru_rd_vld_i ==1)):
            fifo_rest_en     = reg_fifo_cnt <= const.SORT_PERF_PREFETCH_DEPTH - 2*const.SORT_FUC_BK_NUM
        else:
            fifo_rest_en     = reg_fifo_cnt <= const.SORT_PERF_PREFETCH_DEPTH - const.SORT_FUC_BK_NUM

        cur_state_rst_en     = (reg_prefetch_state == self.state_rst)
        cur_state_new_sbu_en = (reg_prefetch_state == self.state_new_sbu)
        cur_state_cnt_mem_en = (reg_prefetch_state == self.state_cnt_mem)

        pru2sbu_rd_vld      = cur_state_new_sbu_en
        pru2sbu_rd_addr     = reg_prefetch_sbu_cnt

        [sbu2pru_rd_vld,
         sbu2rud_rd_addr,
         sbu2pru_rd_data] = self.sbu.sort_sbu_rd_func(ctrl_rd_sel,pru2sbu_rd_vld,pru2sbu_rd_addr)
        
        reg_prefetch_mem_cnt_d = reg_prefetch_mem_cnt

        ## generate sbu rd and addr rd
        if(cur_state_rst_en == 1): ## state rst
            next_state             = self.state_new_sbu        if ctrl2pru_start_vld_i else self.state_rst
            reg_prefetch_sbu_cnt_d = self.para_sbu_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0
            reg_prefetch_mem_cnt_d = self.para_mem_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0

        if(cur_state_new_sbu_en ==1):  ## state new sbu
            next_state_cnt_mem_en = (sbu2pru_rd_vld ==1) & (sbu2pru_rd_data ==1)

            if(ctrl2pru_config_oder_en_i==1) :
                next_state_rst_en     = (sbu2pru_rd_vld ==1) & (sbu2pru_rd_data ==0) & (reg_prefetch_sbu_cnt == 0)
            else:
                next_state_rst_en     = (sbu2pru_rd_vld ==1) & (sbu2pru_rd_data ==0) & (reg_prefetch_sbu_cnt == self.para_sbu_cnt_max_val)

            if (next_state_cnt_mem_en):
                next_state             = self.state_cnt_mem
                pru2cnt_rd_vld_o       = fifo_rest_en
                pru2cnt_rd_addr_o       = utils.splice_bits(reg_prefetch_sbu_cnt,reg_prefetch_mem_cnt,const.SORT_FUC_SBU_DEPTH_WIDTH,const.SORT_FUC_SBU_TILE_CNT_DEPTH)
                reg_prefetch_sbu_cnt_d = reg_prefetch_sbu_cnt
                if((pru2cnt_rd_vld_o ==1) & (ctrl2pru_config_oder_en_i==1)):
                    reg_prefetch_mem_cnt_d = reg_prefetch_mem_cnt - 1
                elif((pru2cnt_rd_vld_o ==1) & (ctrl2pru_config_oder_en_i==0)):
                    reg_prefetch_mem_cnt_d = reg_prefetch_mem_cnt + 1

            elif (next_state_rst_en):
                next_state             = self.state_rst
                reg_prefetch_sbu_cnt_d = self.para_sbu_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0
                reg_prefetch_mem_cnt_d = self.para_mem_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0
                pru_fsm_done_vld       = 1
                
            else :
                next_state             = self.state_new_sbu
                reg_prefetch_sbu_cnt_d = (reg_prefetch_sbu_cnt - 1) if (ctrl2pru_config_oder_en_i==1) else (reg_prefetch_sbu_cnt + 1)
                reg_prefetch_mem_cnt_d = reg_prefetch_mem_cnt

        if(cur_state_cnt_mem_en==1): ## state mem
            pru2cnt_rd_vld_o      = fifo_rest_en
            pru2cnt_rd_addr_o     = utils.splice_bits(reg_prefetch_sbu_cnt,reg_prefetch_mem_cnt,const.SORT_FUC_SBU_DEPTH_WIDTH,const.SORT_FUC_SBU_TILE_CNT_DEPTH)

            ## get next state based on cur state and order_en
            if((ctrl2pru_config_oder_en_i==1)):
                next_state_cnt_mem_en = (reg_prefetch_mem_cnt != 0)
                
                next_state_rst_en     = (reg_prefetch_mem_cnt == 0) & (reg_prefetch_sbu_cnt == 0) & (pru2cnt_rd_vld_o ==1)
                next_state_new_sbu_en = (reg_prefetch_mem_cnt == 0) & (reg_prefetch_sbu_cnt != 0) & (pru2cnt_rd_vld_o ==1)
            else:
                next_state_cnt_mem_en = (reg_prefetch_mem_cnt != self.para_mem_cnt_max_val)
                
                next_state_rst_en     = (reg_prefetch_mem_cnt == self.para_mem_cnt_max_val) & (reg_prefetch_sbu_cnt == self.para_sbu_cnt_max_val) & (pru2cnt_rd_vld_o ==1)
                next_state_new_sbu_en = (reg_prefetch_mem_cnt == self.para_mem_cnt_max_val) & (reg_prefetch_sbu_cnt != self.para_sbu_cnt_max_val) & (pru2cnt_rd_vld_o ==1)
            
            if (next_state_cnt_mem_en):
                next_state             = self.state_cnt_mem
                reg_prefetch_sbu_cnt_d = reg_prefetch_sbu_cnt
                #reg_prefetch_mem_cnt_d = (reg_prefetch_mem_cnt - 1) if pru2cnt_rd_vld_o else reg_prefetch_mem_cnt   
                if((pru2cnt_rd_vld_o==1) & (ctrl2pru_config_oder_en_i==1)):
                    reg_prefetch_mem_cnt_d = (reg_prefetch_mem_cnt - 1)
                elif((pru2cnt_rd_vld_o==1) & (ctrl2pru_config_oder_en_i==0)):
                    reg_prefetch_mem_cnt_d = (reg_prefetch_mem_cnt + 1)

            elif (next_state_rst_en):
                next_state             = self.state_rst  
                pru_fsm_done_vld       = 1
                reg_prefetch_sbu_cnt_d = self.para_sbu_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0
                reg_prefetch_mem_cnt_d = self.para_mem_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0

            elif (next_state_new_sbu_en) :
                next_state             = self.state_new_sbu
                reg_prefetch_sbu_cnt_d = (reg_prefetch_sbu_cnt -1) if (ctrl2pru_config_oder_en_i==1) else (reg_prefetch_sbu_cnt +1)
                reg_prefetch_mem_cnt_d = self.para_mem_cnt_max_val if (ctrl2pru_config_oder_en_i==1) else 0

            else :
                next_state             = reg_prefetch_state
                reg_prefetch_sbu_cnt_d = reg_prefetch_sbu_cnt
                reg_prefetch_mem_cnt_d = reg_prefetch_mem_cnt


        ## update reg

        self.sbu.sort_sbu_wr_func(ctrl_wr_sel,agu2pru_sbu_wr_vld_i,agu2pru_sbu_wr_addr_i)

        self.pru_reg_prefetch_state.set_reg_d(next_state)
        cnt_update_vld = (cur_state_new_sbu_en==1) | (cur_state_cnt_mem_en==1) | (cur_state_rst_en ==1)
        self.pru_reg_prefetch_sbu_cnt.set_reg_d_with_en(cnt_update_vld, reg_prefetch_sbu_cnt_d)
        self.pru_reg_prefetch_mem_cnt.set_reg_d_with_en(cnt_update_vld, reg_prefetch_mem_cnt_d)

        return [
                pru_fsm_done_vld,
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
               ]             
    
    def pru_fsm_without_prefetch_func(self,
        ## input 
        cnt2pru_rd_1f_vld_i, ## 1f
        cnt2pru_rd_vld_i   , ## 2f
        ## from control
        ctrl2pru_start_vld_i,    
        #ctrl2pru_config_oder_en_i, 
        
        pru_reg_cnt_rd_data_vld
        ):
                
        reg_nprefetch_state    = self.pru_reg_nprefetch_state.get_reg_q()
        reg_nprefetch_mem_cnt  = self.pru_reg_nprefetch_mem_cnt.get_reg_q()

        pru_fsm_done_vld      = 0
        pru2cnt_rd_vld_o      = 0
        pru2cnt_rd_addr_o     = 0

        cur_state_rst_en     = (reg_nprefetch_state == self.nprefetch_state_rst)
        cur_state_cnt_mem_en = (reg_nprefetch_state == self.nprefetch_state_cnt_mem)

        if(cur_state_rst_en == 1): ## state rst
            next_state              = self.nprefetch_state_cnt_mem if ctrl2pru_start_vld_i else self.state_rst
            reg_nprefetch_mem_cnt_d = reg_nprefetch_mem_cnt
        if(cur_state_cnt_mem_en == 1): ## state rd cnt_mem 
            pru2cnt_rd_vld_o      = (pru_reg_cnt_rd_data_vld == 0) & (cnt2pru_rd_1f_vld_i ==0) & (cnt2pru_rd_vld_i ==0)
            pru2cnt_rd_addr_o     = reg_nprefetch_mem_cnt

            next_state_cnt_mem_en = reg_nprefetch_mem_cnt != 0
            next_state_rst_en     = (reg_nprefetch_mem_cnt == 0) & (pru2cnt_rd_vld_o==1)

            if (next_state_cnt_mem_en):
                next_state              = self.nprefetch_state_cnt_mem
                if(pru2cnt_rd_vld_o==1):
                    reg_nprefetch_mem_cnt_d = (reg_nprefetch_mem_cnt - 1)
                else:
                    reg_nprefetch_mem_cnt_d = reg_nprefetch_mem_cnt

            elif (next_state_rst_en):
                next_state              = self.nprefetch_state_rst 
                pru_fsm_done_vld        = 1
                reg_nprefetch_mem_cnt_d = self.para_nprefetch_mem_cnt_max_val
            else:
                next_state              = reg_nprefetch_state
                reg_nprefetch_mem_cnt_d = reg_nprefetch_mem_cnt
    
        ## update regs
        self.pru_reg_nprefetch_state.set_reg_d(next_state)
        self.pru_reg_nprefetch_mem_cnt.set_reg_d_with_en(cur_state_cnt_mem_en,reg_nprefetch_mem_cnt_d)  

        return [
                pru_fsm_done_vld,
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
               ] 

        
