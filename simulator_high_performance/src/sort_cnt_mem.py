import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_common.cbb.memory            import memory
from simulator_high_performance.top.const   import const


class cnt_mem:
    def __init__(self): 
        self.cnt_mem = memory(const.SORT_FUC_CNT_MEM_DEPTH, const.SORT_FUC_BK_NUM, const.SORT_FUC_CNT_MEM_WIDTH)

    def cnt_mem_wr(self, vld, addr, data):
        if(vld):
            wr_vld = np.ones(const.SORT_FUC_BK_NUM,dtype=int)
            self.cnt_mem.wr_mem(wr_vld,addr,data)
    def cnt_mem_rd(self, vld, addr):
        rd_data = np.zeros(const.SORT_FUC_BK_NUM,dtype=int)
        if(vld):
            rd_vld = np.ones(const.SORT_FUC_BK_NUM,dtype=int)
            rd_data = self.cnt_mem.rd_mem(rd_vld,addr)
        return rd_data
            