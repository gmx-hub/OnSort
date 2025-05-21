import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_common.cbb.reg              import reg
from simulator.top.const                   import const

from simulator_common.utils.logging_config import logging_config

from simulator.src.sort_cnt_mem            import cnt_mem
from simulator.src.sort_agu                import sort_agu


## count unit class simulate the behavior of count unit module in hardware

class sort_cnt_unit:
    def __init__(self):
        self.logger = logging_config(__name__)
        ## define submodule
        self.cnt_mem = cnt_mem()
        
        ## define reg
        # pipe 1
        self.cnt_reg_cnt_rd_1f_vld  = reg(0)
        self.cnt_reg_cnt_rd_1f_addr = reg(0)
        self.cnt_reg_cnt_rd_1f_bkid = reg(0)

        self.cnt_reg_pru_rd_1f_vld  = reg(0)
        # pipe 2
        self.cnt_reg_addr_same_2f_vld = reg(0)
        self.cnt_reg_addr_same_2f_cnt = reg(np.zeros(const.SORT_FUC_BK_NUM,dtype=int))

        self.cnt_reg_pru_rd_2f_vld  = reg(0)

        self.cnt_reg_cnt_rd_2f_vld  = reg(0)
        self.cnt_reg_cnt_rd_2f_data = reg(np.zeros(const.SORT_FUC_BK_NUM,dtype=int))
        self.cnt_reg_cnt_rd_2f_addr = reg(0)
        self.cnt_reg_cnt_rd_2f_bkid = reg(0)

        self.cnt_reg_pru_rd_2f_vld  = reg(0)
        #pipe 3
        self.cnt_reg_addr_same_3f_vld = reg(0)
        self.cnt_reg_addr_same_3f_cnt = reg(0)

        self.cnt_reg_cnt_rd_3f_vld  = reg(0)       
        self.cnt_reg_cnt_rd_3f_data = reg(np.zeros(const.SORT_FUC_BK_NUM,dtype=int))
        self.cnt_reg_cnt_rd_3f_addr = reg(0)
        self.cnt_reg_cnt_rd_3f_bkid = reg(0)

    def cnt_unit_get_state(self,
                           agu2cnt_vld_i
                           ):
        reg_pru_rd_1f_vld    = self.cnt_reg_pru_rd_1f_vld .get_reg_q()
        reg_pru_rd_2f_vld    = self.cnt_reg_pru_rd_2f_vld .get_reg_q()

        reg_cnt_rd_1f_vld    = self.cnt_reg_cnt_rd_1f_vld .get_reg_q()
        reg_cnt_rd_2f_vld    = self.cnt_reg_cnt_rd_2f_vld .get_reg_q()
        reg_cnt_rd_2f_data   = self.cnt_reg_cnt_rd_2f_data.get_reg_q()
        reg_cnt_rd_2f_addr   = self.cnt_reg_cnt_rd_2f_addr.get_reg_q() 
        reg_cnt_rd_3f_vld    = self.cnt_reg_cnt_rd_3f_vld .get_reg_q()       

        cnt2pru_rd_vld_o    = reg_pru_rd_2f_vld
        cnt2pru_rd_1f_vld_o = reg_pru_rd_1f_vld
        cnt2pru_rd_addr_o   = reg_cnt_rd_2f_addr
        cnt2pru_rd_data_o   = reg_cnt_rd_2f_data

        ## ctrl output
        cntu2ctrl_wr_done_vld_o = (agu2cnt_vld_i==0) & (reg_cnt_rd_1f_vld==0) & (reg_cnt_rd_2f_vld==0) & (reg_cnt_rd_3f_vld==0)

        return [
                ## define output of cnt_unit module
                cnt2pru_rd_vld_o,
                cnt2pru_rd_1f_vld_o,
                cnt2pru_rd_addr_o,
                cnt2pru_rd_data_o,

                cntu2ctrl_wr_done_vld_o]

 
    def cnt_unit_fuc(self,
                  ## define input of count unit module

                  ## from pru-prefetch
                  pru2cnt_rd_vld_i,
                  pru2cnt_rd_addr_i,

                  ## from agu
                  agu2cnt_vld_i,
                  agu2cnt_addr_i,
                  agu2cnt_bankid_i
                  ):
        # read all reg
        reg_cnt_rd_1f_vld    = self.cnt_reg_cnt_rd_1f_vld .get_reg_q() 
        reg_cnt_rd_1f_addr   = self.cnt_reg_cnt_rd_1f_addr.get_reg_q()
        reg_cnt_rd_1f_bkid   = self.cnt_reg_cnt_rd_1f_bkid.get_reg_q()
        reg_pru_rd_1f_vld    = self.cnt_reg_pru_rd_1f_vld.get_reg_q()
        reg_addr_same_2f_vld = self.cnt_reg_addr_same_2f_vld.get_reg_q()
        reg_addr_same_2f_cnt = self.cnt_reg_addr_same_2f_cnt.get_reg_q()
        reg_pru_rd_2f_vld    = self.cnt_reg_pru_rd_2f_vld.get_reg_q()
        reg_cnt_rd_2f_vld    = self.cnt_reg_cnt_rd_2f_vld .get_reg_q()
        reg_cnt_rd_2f_data   = self.cnt_reg_cnt_rd_2f_data.get_reg_q()
        reg_cnt_rd_2f_addr   = self.cnt_reg_cnt_rd_2f_addr.get_reg_q()
        reg_cnt_rd_2f_bkid   = self.cnt_reg_cnt_rd_2f_bkid.get_reg_q()
        reg_addr_same_3f_vld = self.cnt_reg_addr_same_3f_vld.get_reg_q()
        reg_addr_same_3f_cnt = self.cnt_reg_addr_same_3f_cnt.get_reg_q()
        reg_cnt_rd_3f_vld    = self.cnt_reg_cnt_rd_3f_vld .get_reg_q()     
        reg_cnt_rd_3f_data   = self.cnt_reg_cnt_rd_3f_data.get_reg_q()
        reg_cnt_rd_3f_addr   = self.cnt_reg_cnt_rd_3f_addr.get_reg_q()
        reg_cnt_rd_3f_bkid   = self.cnt_reg_cnt_rd_3f_bkid.get_reg_q()


        ## agu addr check
        addr_same_1f_en  = (agu2cnt_addr_i == reg_cnt_rd_1f_addr)
        addr_same_1f_vld = (agu2cnt_vld_i == 1) & (reg_cnt_rd_1f_vld == 1) & (addr_same_1f_en == 1)
        addr_same_1f_cnt = np.zeros(const.SORT_FUC_BK_NUM)
        if(addr_same_1f_vld): 
            addr_same_1f_cnt[agu2cnt_bankid_i] = 1

        addr_same_2f_en  = (agu2cnt_addr_i == reg_cnt_rd_2f_addr)
        addr_same_2f_vld = (agu2cnt_vld_i == 1) & (reg_cnt_rd_2f_vld ==1 ) & (addr_same_2f_en == 1)
        addr_same_2f_cnt = reg_addr_same_2f_cnt if reg_addr_same_2f_vld else np.zeros(const.SORT_FUC_BK_NUM)
        if(addr_same_2f_vld) :
            addr_same_2f_cnt[agu2cnt_bankid_i] = addr_same_2f_cnt[agu2cnt_bankid_i] + 1

        addr_same_3f_en  = (agu2cnt_addr_i == reg_cnt_rd_3f_addr)
        addr_same_3f_vld = (agu2cnt_vld_i == 1) & (reg_cnt_rd_3f_vld ==1 ) & (addr_same_3f_en == 1)
        addr_same_3f_cnt = reg_addr_same_3f_cnt if reg_addr_same_3f_vld else np.zeros(const.SORT_FUC_BK_NUM)
        if(addr_same_3f_vld):
            addr_same_3f_cnt[agu2cnt_bankid_i] = addr_same_3f_cnt[agu2cnt_bankid_i] + 1

        ## memory or reg port
        cnt_rd_vld  = (pru2cnt_rd_vld_i == 1 ) | ((agu2cnt_vld_i == 1) & (addr_same_1f_vld == 0) & (addr_same_2f_vld == 0) & (addr_same_3f_vld == 0))
        cnt_rd_addr = 0
        cnt_rd_bkid = 0
        if pru2cnt_rd_vld_i == 1:
            cnt_rd_addr = pru2cnt_rd_addr_i
        elif agu2cnt_vld_i == 1:
            cnt_rd_addr = agu2cnt_addr_i
            cnt_rd_bkid = agu2cnt_bankid_i
           

        reg_cnt_rd_1f_data = self.cnt_mem.cnt_mem_rd(reg_cnt_rd_1f_vld, reg_cnt_rd_1f_addr) ## to simulate one cycle delay when rd mem

        
        cnt_wr_vld      = (reg_cnt_rd_3f_vld == 1)
        cnt_wr_addr     = reg_cnt_rd_3f_addr
        cnt_wr_data     = (reg_cnt_rd_3f_data + addr_same_3f_cnt) if cnt_wr_vld else np.zeros(const.SORT_FUC_BK_NUM)
        if(reg_cnt_rd_3f_vld):
            cnt_wr_data[reg_cnt_rd_3f_bkid] = cnt_wr_data[reg_cnt_rd_3f_bkid] + 1

        pru_wr_vld      = reg_pru_rd_2f_vld
        pru_wr_addr     = reg_cnt_rd_2f_addr
        pru_wr_data     = np.zeros(const.SORT_FUC_BK_NUM)

        cnt_mem_wr_vld  = cnt_wr_vld | pru_wr_vld
        cnt_mem_wr_addr = cnt_wr_addr if (cnt_wr_vld ==1) else pru_wr_addr
        cnt_mem_wr_data = cnt_wr_data if (cnt_wr_vld ==1) else pru_wr_data

        self.cnt_mem.cnt_mem_wr(cnt_mem_wr_vld, cnt_mem_wr_addr, cnt_mem_wr_data)

        ## update regs
        cnt_reg_cnt_rd_3f_vld_d = (reg_cnt_rd_2f_vld == 1) & (reg_pru_rd_2f_vld == 0)
        self.cnt_reg_cnt_rd_3f_vld .set_reg_d(cnt_reg_cnt_rd_3f_vld_d)

        self.cnt_reg_cnt_rd_1f_vld    .set_reg_d        (cnt_rd_vld)
        self.cnt_reg_cnt_rd_1f_addr   .set_reg_d_with_en(cnt_rd_vld,cnt_rd_addr)
        self.cnt_reg_cnt_rd_1f_bkid   .set_reg_d_with_en(cnt_rd_vld,cnt_rd_bkid)
        self.cnt_reg_pru_rd_1f_vld    .set_reg_d        (pru2cnt_rd_vld_i)
        self.cnt_reg_addr_same_2f_vld .set_reg_d        (addr_same_1f_vld)
        self.cnt_reg_addr_same_2f_cnt .set_reg_d_with_en(addr_same_1f_vld,addr_same_1f_cnt)
        self.cnt_reg_pru_rd_2f_vld    .set_reg_d        (reg_pru_rd_1f_vld)
        self.cnt_reg_cnt_rd_2f_vld    .set_reg_d        (reg_cnt_rd_1f_vld)
        self.cnt_reg_cnt_rd_2f_data   .set_reg_d_with_en(reg_cnt_rd_1f_vld,reg_cnt_rd_1f_data)
        self.cnt_reg_cnt_rd_2f_addr   .set_reg_d_with_en(reg_cnt_rd_1f_vld,reg_cnt_rd_1f_addr)
        self.cnt_reg_cnt_rd_2f_bkid   .set_reg_d_with_en(reg_cnt_rd_1f_vld,reg_cnt_rd_1f_bkid)

        cnt_reg_addr_same_3f_upd_vld = (reg_addr_same_2f_vld==1) | (addr_same_2f_vld==1)
        cnt_reg_addr_same_3f_cnt_d   = addr_same_2f_cnt
        self.cnt_reg_addr_same_3f_vld .set_reg_d        (cnt_reg_addr_same_3f_upd_vld)
        self.cnt_reg_addr_same_3f_cnt .set_reg_d_with_en(cnt_reg_addr_same_3f_upd_vld,cnt_reg_addr_same_3f_cnt_d)
        
        cnt_reg_cnt_rd_3f_vld_d = (reg_cnt_rd_2f_vld == 1) & (reg_pru_rd_2f_vld == 0)
        self.cnt_reg_cnt_rd_3f_vld .set_reg_d        (cnt_reg_cnt_rd_3f_vld_d)     

        self.cnt_reg_cnt_rd_3f_data.set_reg_d_with_en(cnt_reg_cnt_rd_3f_vld_d,reg_cnt_rd_2f_data)
        self.cnt_reg_cnt_rd_3f_addr.set_reg_d_with_en(cnt_reg_cnt_rd_3f_vld_d,reg_cnt_rd_2f_addr)
        self.cnt_reg_cnt_rd_3f_bkid.set_reg_d_with_en(cnt_reg_cnt_rd_3f_vld_d,reg_cnt_rd_2f_bkid)


        ## assert
        if ((pru2cnt_rd_vld_i & agu2cnt_vld_i) == 1):
            raise("Error: pru2cnt_rd_vld and agu2cnt_vld is same at one time" )
        if ((reg_addr_same_3f_vld == 1) & (reg_cnt_rd_3f_vld == 0)):
            raise("Error: reg_addr_same_3f_vld =1 and reg_cnt_rd_3f_vld =0 at one time" )
        
        #debug_info = ('********** 1f pipe  ') + '\n' + \
        #             ('addr_same_1f_vld : ' + str(addr_same_1f_vld)).ljust(22) + '\n' + \
        #             ('addr_same_1f_cnt : ' + str(addr_same_1f_cnt)).ljust(22) + '\n' + \
        #             ('reg_cnt_rd_1f_vld :' + str(reg_cnt_rd_1f_vld)).ljust(22) + '\n' + \
        #             ('reg_cnt_rd_1f_addr :' + str(reg_cnt_rd_1f_addr)).ljust(22) + '\n' + \
        #             ('reg_cnt_rd_1f_data :' + str(reg_cnt_rd_1f_data)).ljust(22) + '\n' + \
        #             ('********** 2f pipe  ') + '\n' + \
        #             ('addr_same_2f_vld :' + str(addr_same_2f_vld)).ljust(22) + '\n' + \
        #             ('addr_same_2f_cnt :' + str(addr_same_2f_cnt)).ljust(22) + '\n' + \
        #             ('********** wr   ') + '\n' + \
        #             ('cnt_wr_vld :' + str(cnt_wr_vld)).ljust(22) + '\n' + \
        #             ('cnt_wr_addr :' + str(cnt_wr_addr)).ljust(22) + '\n' + \
        #             ('cnt_wr_data :' + str(cnt_wr_data)).ljust(22) + '\n' 
         
        #self.logger.debug(debug_info)
