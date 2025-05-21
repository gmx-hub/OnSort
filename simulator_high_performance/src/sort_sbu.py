import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_common.cbb.reg              import reg
from simulator_high_performance.top.const  import const

from simulator_common.utils.logging_config import logging_config

import simulator_common.utils.utils as utils

class sort_sbu:
    def __init__(self):
        self.logger = logging_config(__name__)
        
        ##define reg
        self.sbu_reg_sbu0 = reg(np.zeros(const.SORT_PERF_SBU_NUM,dtype=int))
        self.sbu_reg_sbu1 = reg(np.zeros(const.SORT_PERF_SBU_NUM,dtype=int))

    def sort_sbu_wr_func(self, 
                      ## define input of sbu module
                      ctrl_wr_sel,
                      agu2sbu_wr_vld_i,
                      agu2sbu_wr_addr_i
                      ):
        ## read all reg
        reg_sbu0 = self.sbu_reg_sbu0.get_reg_q()
        reg_sbu1 = self.sbu_reg_sbu1.get_reg_q()

        ## wr sbu
        wr_sbu0 = reg_sbu0
        wr_sbu1 = reg_sbu1
        wr_sbu0_en = (agu2sbu_wr_vld_i==1) & (ctrl_wr_sel==0)
        wr_sbu1_en = (agu2sbu_wr_vld_i==1) & (ctrl_wr_sel==1)
        if(wr_sbu0_en):
            wr_sbu0[agu2sbu_wr_addr_i] = 1
        elif(wr_sbu1_en):
            wr_sbu1[agu2sbu_wr_addr_i] = 1
        
        self.sbu_reg_sbu0.set_reg_d_with_en(wr_sbu0_en,wr_sbu0)
        self.sbu_reg_sbu1.set_reg_d_with_en(wr_sbu1_en,wr_sbu1)

    def sort_sbu_rd_func(self,
                         ctrl_rd_sel,
                         rdu2sbu_rd_vld_i,
                         rdu2sbu_rd_addr_i               
                        ):
        ## raed sbu
        reg_sbu0 = self.sbu_reg_sbu0.get_reg_q()
        reg_sbu1 = self.sbu_reg_sbu1.get_reg_q()

        sbu2rdu_rd_vld_o  = rdu2sbu_rd_vld_i
        sbu2rdu_rd_data_o = reg_sbu1[rdu2sbu_rd_addr_i] if (ctrl_rd_sel==1) else reg_sbu0[rdu2sbu_rd_addr_i]
        sbu2rud_rd_addr_o = rdu2sbu_rd_addr_i   

        sbu0_clr_en = (rdu2sbu_rd_vld_i==1) & (ctrl_rd_sel==0)
        sbu1_clr_en = (rdu2sbu_rd_vld_i==1) & (ctrl_rd_sel==1)
        if(sbu0_clr_en):
            reg_sbu0[rdu2sbu_rd_addr_i] = 0
        elif(sbu1_clr_en):
            reg_sbu1[rdu2sbu_rd_addr_i] = 0

        self.sbu_reg_sbu0.set_reg_d_with_en(sbu0_clr_en,reg_sbu0)
        self.sbu_reg_sbu1.set_reg_d_with_en(sbu1_clr_en,reg_sbu1)

        return [
            sbu2rdu_rd_vld_o,
            sbu2rud_rd_addr_o,
            sbu2rdu_rd_data_o
            ]
