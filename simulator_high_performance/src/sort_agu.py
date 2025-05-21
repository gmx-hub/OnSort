import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import random

from simulator_common.cbb.reg               import reg
from simulator_high_performance.top.const   import const

from simulator_common.utils.logging_config  import logging_config 

import simulator_common.utils.utils as utils


## agu (addr generation unit) class simulate the behavior of AGU module in hardware 

class sort_agu:
    def __init__(self):
       
        ## define reg 
        self.logger = logging_config(__name__)

    def __mem_gen(self,agu_reg_data_q):
        
        return [
               utils.extract_bits(agu_reg_data_q,const.SORT_FUC_BK_DEPTH_WIDTH,const.SORT_FUC_DATA_BANDWIDTH-1), 
               ## [bk7,bk6,bk5,bk4,bk3,bk2,bk1,bk0] <-> bkid:[0,1,2,3,4,5,6,7](need const.SORT_FUC_BK_NUM -1 - x)
               const.SORT_FUC_BK_NUM -1- utils.extract_bits(agu_reg_data_q,0,const.SORT_FUC_BK_DEPTH_WIDTH-1)
        ]
    
    def __sbu_gen(self,agu_reg_data_q):
        return [
               utils.extract_bits(agu_reg_data_q,const.SORT_FUC_SBU_TILE_WIDTH,const.SORT_FUC_DATA_BANDWIDTH-1),            
               utils.extract_bits(agu_reg_data_q,0,const.SORT_FUC_SBU_TILE_WIDTH-1)
        ]      


    def agu_func(self, 
                ## define input of AGU module
                agu_vld_i,
                agu_data_i
                ):

        ## func
        agu2sbu_vld_o      = agu_vld_i
        agu2cnt_vld_o      = agu_vld_i

        agu2sbu_addr_o, agu2sbu_id_o     = self.__sbu_gen(agu_data_i)
        agu2cnt_addr_o, agu2cnt_bankid_o = self.__mem_gen(agu_data_i)

        ## assert
        if( agu2cnt_bankid_o<0):
            print("Error-agu2cnt_bankid_o :",agu2cnt_bankid_o)
            raise("Error: bkid is negative!")

        ## log debug
        
        #debug_info = ('**********   ') + \
        #             ('agu2sbu_vld_o :' + str(agu2sbu_vld_o)).ljust(22) + \
        #             ('agu2sbu_addr_o :' + str(agu2sbu_addr_o)).ljust(22) + \
        #             ('agu2sbu_id_o :' + str(agu2sbu_id_o)).ljust(22) + \
        #             ('agu2mem_vld_o :' + str(agu2cnt_vld_o)).ljust(22) + \
        #             ('agu2mem_addr_o :' + str(agu2cnt_addr_o)).ljust(22) + \
        #             ('agu2mem_bankid_o :' + str(agu2cnt_bankid_o)).ljust(22) 
        # 
        #self.logger.debug(debug_info)

        return [
                ## define output of AGU module
                agu2sbu_vld_o,
                agu2sbu_addr_o,
                agu2sbu_id_o,

                agu2cnt_vld_o,
                agu2cnt_addr_o,
                agu2cnt_bankid_o
        ]





