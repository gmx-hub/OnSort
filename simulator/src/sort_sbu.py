import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_common.cbb.reg              import reg
from simulator.top.const                   import const

from simulator_common.utils.logging_config import logging_config

import simulator_common.utils.utils as utils

class sort_sbu:
    def __init__(self):
        self.logger = logging_config(__name__)
        
        ##define reg
        self.sbu_reg_sbu = reg(np.zeros(const.SORT_PERF_SBU_NUM,dtype=int))

    def sort_sbu_wr_func(self, 
                      ## define input of sbu module
                      agu2sbu_wr_vld_i,
                      agu2sbu_wr_addr_i
                      ):
        ## read all reg
        reg_sbu = self.sbu_reg_sbu.get_reg_q()

        ## wr sbu
        wr_sbu = reg_sbu
        if(agu2sbu_wr_vld_i):
            wr_sbu[agu2sbu_wr_addr_i] = 1
        
        self.sbu_reg_sbu.set_reg_d_with_en(agu2sbu_wr_vld_i,wr_sbu)

    def sort_sbu_rd_func(self,
                         pru2sbu_rd_vld_i,
                         pru2sbu_rd_addr_i               
                        ):
        ## raed sbu
        reg_sbu = self.sbu_reg_sbu.get_reg_q()
        sbu2pru_rd_vld_o  = pru2sbu_rd_vld_i
        sbu2pru_rd_data_o = reg_sbu[pru2sbu_rd_addr_i]
        sbu2rud_rd_addr_o = pru2sbu_rd_addr_i   

        if(pru2sbu_rd_vld_i):
            reg_sbu[pru2sbu_rd_addr_i] = 0

        self.sbu_reg_sbu.set_reg_d_with_en(pru2sbu_rd_vld_i,reg_sbu)

        return [
            sbu2pru_rd_vld_o,
            sbu2rud_rd_addr_o,
            sbu2pru_rd_data_o
            ]
