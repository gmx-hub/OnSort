import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_common.cbb.reg                import reg
from simulator.top.const                     import const

from simulator_common.utils.logging_config   import logging_config
from simulator.src.sort_cnt_mem              import cnt_mem
from simulator.src.sort_agu                  import sort_agu
from simulator.src.sort_pru_fsm              import sort_pru_fsm

import simulator_common.utils.utils as utils

import pdb

## pru unit class simulate the behavior of read unit module in hardware
class sort_pru:
    def __init__(self):    
        self.logger = logging_config(__name__)

        ## basic function
        self.pru_reg_fsm_done_flag    = reg(0)
    
        ## prefetch function
        ## define submodule
        self.pru_fsm = sort_pru_fsm()
        ## reg 
        self.pru_reg_prefetch_fifo    = reg(np.zeros(const.SORT_PERF_PREFETCH_DEPTH,dtype=np.int64))
        self.pru_reg_fifo_rd_ptr      = reg(0)
        self.pru_reg_fifo_wr_ptr      = reg(0)
        self.pru_reg_fifo_cnt         = reg(0)

        ## without prefetch function
        self.pru_reg_cnt_rd_data_vld  = reg(0)
        self.pru_reg_cnt_rd_data      = reg(np.zeros(const.SORT_FUC_BK_NUM,dtype=int))
        self.pru_reg_cnt_rd_data_idx  = reg(0)
        self.pru_reg_cnt_num          = reg(const.SORT_FUC_MAX_NUM-1)

        ## define some wire
        self.pru_fsm_done_vld         = 0
        self.pru_interface_idle_en    = 0

    def pru_with_prefetch_generate_addr(self,
                                        ## from control
                                        ctrl2pru_start_vld_i, 
                                        ctrl2pru_config_oder_en_i,
                                        ## from agu
                                        agu2pru_sbu_wr_vld_i,
                                        agu2pru_sbu_wr_addr_i,                                                            
                                        ## from cntu
                                        cnt2pru_rd_1f_vld_i, ## 1f
                                        cnt2pru_rd_vld_i     ## 2f        
                                        ):
        reg_fifo_cnt          = self.pru_reg_fifo_cnt.get_reg_q()

        ## prefetch fsm function
        [
            self.pru_fsm_done_vld,
            pru2cnt_rd_vld_o,
            pru2cnt_rd_addr_o
           ] = self.pru_fsm.pru_fsm_prefetch_func(
                                                  ctrl2pru_start_vld_i, 
                                                  ctrl2pru_config_oder_en_i,
                                                  agu2pru_sbu_wr_vld_i,
                                                  agu2pru_sbu_wr_addr_i,
                                                  cnt2pru_rd_1f_vld_i, ## 1f
                                                  cnt2pru_rd_vld_i,  ## 2f
                                                  reg_fifo_cnt)
        
        self.pru_interface_idle_en = (pru2cnt_rd_vld_o==0) & (cnt2pru_rd_1f_vld_i ==0) & (cnt2pru_rd_vld_i ==0)
        
        return [
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
               ]
    
    def pru_without_prefetch_generate_addr(self,
                                           cnt2pru_rd_1f_vld_i, ## 1f
                                           cnt2pru_rd_vld_i   , ## 2f
                                           ctrl2pru_start_vld_i
                                           ):
        
        reg_cnt_rd_data_vld = self.pru_reg_cnt_rd_data_vld.get_reg_q()

        [
            self.pru_fsm_done_vld,
            pru2cnt_rd_vld_o,
            pru2cnt_rd_addr_o
           ] = self.pru_fsm.pru_fsm_without_prefetch_func(
                                                  cnt2pru_rd_1f_vld_i, ## 1f
                                                  cnt2pru_rd_vld_i   , ## 2f
                                                  ctrl2pru_start_vld_i, 
                                                  reg_cnt_rd_data_vld)
        
        return [
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
               ]        

    def pru_with_prefetch_func(self, ## use prefetch func to improve perfermance
                 ## input port 
                 ctrl2pru_config_oder_en_i,
                 ## from cntu
                 cnt2pru_rd_vld_i,  ## 2f
                 cnt2pru_rd_addr_i,
                 cnt2pru_rd_data_i     
                 ):

        reg_prefetch_fifo     = self.pru_reg_prefetch_fifo.get_reg_q()
        reg_fifo_rd_ptr       = self.pru_reg_fifo_rd_ptr.get_reg_q()
        reg_fifo_wr_ptr       = self.pru_reg_fifo_wr_ptr.get_reg_q()
        reg_fifo_cnt          = self.pru_reg_fifo_cnt.get_reg_q()
        reg_fsm_done_flag     = self.pru_reg_fsm_done_flag.get_reg_q()
        
        ## rd data from prefetch fifo and output data. output port can be setted as 1/2/4, means design can output 1/2/4 data at one time.
        #print("reg_fifo_cnt",reg_fifo_cnt)
        prefetch_fifo_rd_info    = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=np.int64)
        pru2output_data_pre      = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        prefetch_fifo_rd_cnt_num = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        fifo_rd_addr             = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        fifo_wr_wb_vld_pre       = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        fifo_wr_wb_cnt_num_pre   = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        fifo_wr_wb_data_pre      = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=np.int64)
        pru_idx0_en                 = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        pru_idx1_en                 = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        pru_idx2_en                 = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        pru_idx3_en                 = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        fifo_rd_en                  = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)

        pru2output_data_vld      = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)
        pru2output_data          = np.zeros(const.SORT_PERF_OUT_PARALLEL,dtype=int)


        for i in range (const.SORT_PERF_OUT_PARALLEL):
            fifo_rd_addr            [i] = utils.adder_under_bitlimit(reg_fifo_rd_ptr, i, const.SORT_FUC_PREFETCH_DEPTH_WIDTH)
            prefetch_fifo_rd_info   [i] = reg_prefetch_fifo[fifo_rd_addr[i]]
            pru2output_data_pre     [i] = utils.extract_bits(prefetch_fifo_rd_info[i],const.SORT_FUC_CNT_MEM_WIDTH,(const.SORT_FUC_CNT_MEM_WIDTH +const.SORT_FUC_DATA_BANDWIDTH-1))
            prefetch_fifo_rd_cnt_num[i] = utils.extract_bits(prefetch_fifo_rd_info[i],0,const.SORT_FUC_CNT_MEM_WIDTH-1)
                      
        ## port 1
        pru_idx0_en                [0] = (reg_fifo_cnt !=0)
        pru2output_data_vld        [0] = pru_idx0_en[0]
        pru2output_data            [0] = pru2output_data_pre[0]

        fifo_rd_en                 [0] = pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]==1)

        fifo_wr_wb_vld_pre    [0] = pru_idx0_en[0]
        fifo_wr_wb_cnt_num_pre[0] = (prefetch_fifo_rd_cnt_num[0] -1) if prefetch_fifo_rd_cnt_num[0]>=1 else prefetch_fifo_rd_cnt_num[0]

        fifo_wr_wb_data_pre   [0] = utils.splice_bits(pru2output_data_pre[0],fifo_wr_wb_cnt_num_pre[0],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

        ## port 2 if have
        if (const.SORT_PERF_OUT_PARALLEL >= 2):
            pru_idx0_en        [1] = (pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]>=2))
            pru_idx1_en        [1] = (reg_fifo_cnt > 1) & (pru_idx0_en[1]==0)
            pru2output_data_vld[1] = pru_idx0_en[1] | pru_idx1_en[1]
            pru2output_data    [1] = pru2output_data_pre[0] if pru_idx0_en[1] else pru2output_data_pre[1]

            fifo_rd_en[0]          = \
                                     (pru_idx0_en[1] & (prefetch_fifo_rd_cnt_num[0]==2) ) | \
                                     (pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]==1) )
            
            fifo_rd_en[1]          = pru_idx1_en[1] & (prefetch_fifo_rd_cnt_num[1]==1)

            fifo_wr_wb_vld_pre    [0] = pru_idx0_en[0] | pru_idx0_en[1]
            fifo_wr_wb_cnt_num_pre[0] = prefetch_fifo_rd_cnt_num[0] - (pru_idx0_en[0] + pru_idx0_en[1]) if (prefetch_fifo_rd_cnt_num[0] >= (pru_idx0_en[0] + pru_idx0_en[1])) else prefetch_fifo_rd_cnt_num[0]
            fifo_wr_wb_data_pre   [0] = utils.splice_bits(pru2output_data_pre[0],fifo_wr_wb_cnt_num_pre[0],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

            fifo_wr_wb_vld_pre    [1] = pru_idx1_en[1]
            fifo_wr_wb_cnt_num_pre[1] = (prefetch_fifo_rd_cnt_num[1] - 1) if prefetch_fifo_rd_cnt_num[1]>=1 else prefetch_fifo_rd_cnt_num[1]
            fifo_wr_wb_data_pre   [1] = utils.splice_bits(pru2output_data_pre[1],fifo_wr_wb_cnt_num_pre[1],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

        ## port 0/1/2/3 (have 4 output port)
        ##         
        ##         case0 case1 case2 case3 case4 case5 case6 case7 (FIFO_rd_entry_num)
        ## port0   0     0     0     0     0     0     0     0
        ## port1   0     0     0     0     1     1     1     1
        ## port2   0     0     1     1     1     1     2     2
        ## port3   0     1     1     2     1     2     2     3
        
        if (const.SORT_PERF_OUT_PARALLEL == 4):

            pru_idx0_en        [2] = (pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]>=3))
            pru_idx1_en        [2] = (pru_idx0_en[0] & pru_idx0_en[1] & (prefetch_fifo_rd_cnt_num[0]==2) & ((reg_fifo_cnt > 1))) | \
                                     (pru_idx0_en[0] & pru_idx1_en[1] & (prefetch_fifo_rd_cnt_num[1]>=2))
                                     
            pru_idx2_en        [2] = (reg_fifo_cnt > 2) & (pru_idx0_en[2]==0) & (pru_idx1_en[2]==0)

            pru2output_data_vld[2] = pru_idx0_en[2] | pru_idx1_en[2] | pru_idx2_en[2]
            if pru_idx0_en[2]:
                pru2output_data[2] = pru2output_data_pre[0]
            elif pru_idx1_en[2]:
                pru2output_data[2] = pru2output_data_pre[1]
            elif pru_idx2_en[2]:
                pru2output_data[2] = pru2output_data_pre[2]

            pru_idx0_en        [3] = (pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]>=4))
            pru_idx1_en        [3] = (pru_idx0_en[0] & (prefetch_fifo_rd_cnt_num[0]==3) & ((reg_fifo_cnt > 1))) | \
                                     (pru_idx0_en[0] & pru_idx0_en[1] & pru_idx1_en[2] & (prefetch_fifo_rd_cnt_num[1]>=2))  | \
                                     (pru_idx0_en[0] & pru_idx1_en[1] & pru_idx1_en[2] & (prefetch_fifo_rd_cnt_num[1]>=3))
             
            pru_idx2_en        [3] = (pru_idx2_en[2] & (prefetch_fifo_rd_cnt_num[2]>=2)) | \
                                     (pru_idx0_en[0] & pru_idx0_en[1] & pru_idx1_en[2] & (prefetch_fifo_rd_cnt_num[1]==1) & (reg_fifo_cnt > 2)) | \
                                     (pru_idx0_en[0] & pru_idx1_en[1] & pru_idx1_en[2] & (prefetch_fifo_rd_cnt_num[1]==2) & (reg_fifo_cnt > 2))
            
            pru_idx3_en        [3] = (reg_fifo_cnt > 3) & (pru_idx0_en[3]==0) & (pru_idx1_en[3]==0) & (pru_idx2_en[3]==0)

            pru2output_data_vld[3] = pru_idx0_en[3] | pru_idx1_en[3] | pru_idx2_en[3] | pru_idx3_en[3]
            if pru_idx0_en[3]:
                pru2output_data[3] = pru2output_data_pre[0]
            elif pru_idx1_en[3]:
                pru2output_data[3] = pru2output_data_pre[1]
            elif pru_idx2_en[3]:
                pru2output_data[3] = pru2output_data_pre[2]
            elif pru_idx3_en[3]:
                pru2output_data[3] = pru2output_data_pre[3]


            fifo_wr_wb_vld_pre    [0] = pru_idx0_en[0] | pru_idx0_en[1] | pru_idx0_en[2] | pru_idx0_en[3]
            fifo_wr_wb_cnt_num_pre[0] = prefetch_fifo_rd_cnt_num[0] - np.sum(pru_idx0_en) if (prefetch_fifo_rd_cnt_num[0] >= np.sum(pru_idx0_en)) else prefetch_fifo_rd_cnt_num[0]
            fifo_wr_wb_data_pre   [0] = utils.splice_bits(pru2output_data_pre[0],fifo_wr_wb_cnt_num_pre[0],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

            fifo_wr_wb_vld_pre    [1] = pru_idx1_en[0] | pru_idx1_en[1] | pru_idx1_en[2] | pru_idx1_en[3]
            fifo_wr_wb_cnt_num_pre[1] = prefetch_fifo_rd_cnt_num[1] - np.sum(pru_idx1_en) if (prefetch_fifo_rd_cnt_num[1] >= np.sum(pru_idx1_en)) else prefetch_fifo_rd_cnt_num[1]
            fifo_wr_wb_data_pre   [1] = utils.splice_bits(pru2output_data_pre[1],fifo_wr_wb_cnt_num_pre[1],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

            fifo_wr_wb_vld_pre    [2] = pru_idx2_en[0] | pru_idx2_en[1] | pru_idx2_en[2] | pru_idx2_en[3]
            fifo_wr_wb_cnt_num_pre[2] = prefetch_fifo_rd_cnt_num[2] - np.sum(pru_idx2_en) if (prefetch_fifo_rd_cnt_num[2] >= np.sum(pru_idx2_en)) else prefetch_fifo_rd_cnt_num[2]
            fifo_wr_wb_data_pre   [2] = utils.splice_bits(pru2output_data_pre[2],fifo_wr_wb_cnt_num_pre[2],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)

            fifo_wr_wb_vld_pre    [3] = pru_idx3_en[0] | pru_idx3_en[1] | pru_idx3_en[2] | pru_idx3_en[3]
            fifo_wr_wb_cnt_num_pre[3] = prefetch_fifo_rd_cnt_num[3] - np.sum(pru_idx3_en) if (prefetch_fifo_rd_cnt_num[3] >= np.sum(pru_idx3_en)) else prefetch_fifo_rd_cnt_num[3]
            fifo_wr_wb_data_pre   [3] = utils.splice_bits(pru2output_data_pre[3],fifo_wr_wb_cnt_num_pre[3],const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)
      
            
            fifo_rd_en                 [0] =  np.sum(pru_idx0_en) == prefetch_fifo_rd_cnt_num[0] if np.sum(pru_idx0_en) !=0 else 0
                      
            fifo_rd_en                 [1] =   np.sum(pru_idx1_en) == prefetch_fifo_rd_cnt_num[1] if np.sum(pru_idx1_en) !=0 else 0
       
            fifo_rd_en                 [2] =   np.sum(pru_idx2_en) == prefetch_fifo_rd_cnt_num[2] if np.sum(pru_idx2_en) !=0 else 0

            fifo_rd_en                 [3] =    pru_idx3_en[3] & (prefetch_fifo_rd_cnt_num[3]==1)
        
        ## input data and write fifo
        ## example: cycle_n   cnt2pru_rd_data_i     = [5,2,0,3,2,0,1,0](mem has 8 bank)
        ##                    prefetch_fifo_wr_data = [5,2,3,2,1,0,0,0]
        ##          cycle_n+1 self.pru_reg_prefetch_fifo = [...,5,2,3,2,1,...]
        cnt_rd_data_nzero_en  = (cnt2pru_rd_data_i != 0) ## np.array(const.SORT_FUC_BK_NUM)
        cnt_rd_data_nzero_num = np.sum(cnt_rd_data_nzero_en)
        cnt_rd_info_vld       = np.zeros(const.SORT_FUC_BK_NUM,dtype=int)
        cnt_rd_info           = np.zeros(const.SORT_FUC_BK_NUM,dtype=np.int64)
        prefetch_fifo_upd_vld = np.zeros(const.SORT_PERF_PREFETCH_DEPTH,dtype=int)
        prefetch_fifo_data_d  = np.zeros(const.SORT_PERF_PREFETCH_DEPTH,dtype=np.int64)

        wr_idx                = 0
        for i in range (const.SORT_FUC_BK_NUM): ## in verilog, this func is implemented by mux
            cnt_rd_nzero_en = cnt_rd_data_nzero_en[i] if (ctrl2pru_config_oder_en_i==1) else cnt_rd_data_nzero_en[(const.SORT_FUC_BK_NUM -1 - i)]
            if((cnt_rd_nzero_en == 1) & (cnt2pru_rd_vld_i == 1)):
                cnt_rd_data             = cnt2pru_rd_data_i[i] if (ctrl2pru_config_oder_en_i==1) else cnt2pru_rd_data_i[(const.SORT_FUC_BK_NUM -1 - i)]
                cnt_rd_addr             = cnt2pru_rd_addr_i
                ## [bk7,bk6,bk5,bk4,bk3,bk2,bk1,bk0] <-> cnt_rd_bkid:[0,1,2,3,4,5,6,7] 
                ## if oder_en =1  fifo wr = [bk7,bk6...,bk0] (need const.SORT_FUC_BK_NUM -1 - i)
                ## if oder_en =0  fifo wr = [bk0,bk1,...,bk7]
                cnt_rd_bkid             = (const.SORT_FUC_BK_NUM -1 - i) if (ctrl2pru_config_oder_en_i==1) else i
                cnt_rd_idx_num          = utils.splice_bits(cnt_rd_addr,cnt_rd_bkid,const.SORT_FUC_CNT_MEM_DEPTH_WIDTH,const.SORT_FUC_BK_DEPTH_WIDTH)
                cnt_rd_info_vld[wr_idx] = cnt_rd_nzero_en
                cnt_rd_info[wr_idx]     = utils.splice_bits(cnt_rd_idx_num, cnt_rd_data, const.SORT_FUC_DATA_BANDWIDTH , const.SORT_FUC_CNT_MEM_WIDTH)
                wr_idx                  = wr_idx + 1

        prefetch_fifo_wr_en_pre   = utils.pad_array(cnt_rd_info_vld, const.SORT_PERF_PREFETCH_DEPTH)
        prefetch_fifo_wr_data_pre = utils.pad_array(cnt_rd_info    , const.SORT_PERF_PREFETCH_DEPTH)
        prefetch_fifo_wr_en       = utils.barrel_shifter(prefetch_fifo_wr_en_pre  , reg_fifo_wr_ptr)
        prefetch_fifo_wr_data     = utils.barrel_shifter(prefetch_fifo_wr_data_pre, reg_fifo_wr_ptr)

        prefetch_fifo_wb_en_pre   = utils.pad_array(fifo_wr_wb_vld_pre    , const.SORT_PERF_PREFETCH_DEPTH)
        prefetch_fifo_wb_data_pre = utils.pad_array(fifo_wr_wb_data_pre   , const.SORT_PERF_PREFETCH_DEPTH)
        prefetch_fifo_wb_en       = utils.barrel_shifter(prefetch_fifo_wb_en_pre  , reg_fifo_rd_ptr)
        prefetch_fifo_wb_data     = utils.barrel_shifter(prefetch_fifo_wb_data_pre, reg_fifo_rd_ptr)
        
        ## after fifo rd , cnt_num write back 
        ## assert
        for i in range (const.SORT_PERF_PREFETCH_DEPTH):
            prefetch_fifo_upd_vld[i] = prefetch_fifo_wr_en[i] | prefetch_fifo_wb_en[i]
            prefetch_fifo_data_d [i] = prefetch_fifo_wr_data[i] if prefetch_fifo_wr_en[i] else prefetch_fifo_wb_data[i]

            if((prefetch_fifo_wr_en[i] == 1) & (prefetch_fifo_wb_en[i]==1)):
                print("prefetch_fifo_wr_en,prefetch_fifo_wb_en",prefetch_fifo_wr_en,prefetch_fifo_wb_en)
                raise("Error: fifo wr and fifo rd write back complict")
            
        ##fifo cnt and fifo rpt
        reg_fifo_rd_upd_vld  = np.any(fifo_rd_en != 0)
        reg_fifo_wr_upd_vld  = (cnt2pru_rd_vld_i==1) & (cnt_rd_data_nzero_num !=0)
        reg_fifo_rd_ptr_d = utils.adder_under_bitlimit(reg_fifo_rd_ptr, np.sum(fifo_rd_en)   , const.SORT_FUC_PREFETCH_DEPTH_WIDTH)
        reg_fifo_wr_ptr_d = utils.adder_under_bitlimit(reg_fifo_wr_ptr, cnt_rd_data_nzero_num, const.SORT_FUC_PREFETCH_DEPTH_WIDTH)
        
        #print("reg_fifo_rd_upd_vld",reg_fifo_rd_upd_vld,"reg_fifo_wr_upd_vld",reg_fifo_wr_upd_vld)
        reg_fifo_cnt_sub_en     = (reg_fifo_rd_upd_vld == 1) & (reg_fifo_wr_upd_vld == 0)
        reg_fifo_cnt_sub_add_en = (reg_fifo_rd_upd_vld == 1) & (reg_fifo_wr_upd_vld == 1)
        reg_fifo_cnt_add_en     = (reg_fifo_rd_upd_vld == 0) & (reg_fifo_wr_upd_vld == 1)
        if(reg_fifo_cnt_sub_en):
            reg_fifo_cnt_d = reg_fifo_cnt -  np.sum(fifo_rd_en)
        elif(reg_fifo_cnt_sub_add_en):
            reg_fifo_cnt_d = reg_fifo_cnt + cnt_rd_data_nzero_num - np.sum(fifo_rd_en)
        elif(reg_fifo_cnt_add_en):
            reg_fifo_cnt_d = reg_fifo_cnt + cnt_rd_data_nzero_num
        else:
            reg_fifo_cnt_d = reg_fifo_cnt
        
        ## state to ctrl_unit
        
        pru2ctrl_rd_done_vld_o = (reg_fsm_done_flag ==1) & ((reg_fifo_cnt ==0)) & (self.pru_interface_idle_en==1)
        ## update regs
        self.pru_reg_prefetch_fifo.set_vecreg_d_with_vecen(prefetch_fifo_upd_vld,prefetch_fifo_data_d)
        self.pru_reg_fifo_rd_ptr  .set_reg_d_with_en      (reg_fifo_rd_upd_vld,reg_fifo_rd_ptr_d)
        self.pru_reg_fifo_wr_ptr  .set_reg_d_with_en      (reg_fifo_wr_upd_vld,reg_fifo_wr_ptr_d)
        self.pru_reg_fifo_cnt     .set_reg_d_with_en      (((reg_fifo_rd_upd_vld==1) | (reg_fifo_wr_upd_vld==1)),reg_fifo_cnt_d)
        self.pru_reg_fsm_done_flag.set_reg_d_with_en      (((self.pru_fsm_done_vld==1) | (pru2ctrl_rd_done_vld_o==1)),self.pru_fsm_done_vld)
        ## assert
        if(reg_fifo_cnt < 0):
            print("Error: reg_fifo_cnt",reg_fifo_cnt)
            raise("Error,reg_fifo_cnt is negative!")
        if(reg_fifo_cnt > const.SORT_PERF_PREFETCH_DEPTH):
            print("Error: reg_fifo_cnt",reg_fifo_cnt)
            raise("Error: reg_fifo_cnt is overflw!")
        if(pru2ctrl_rd_done_vld_o == 1 & self.pru_fsm_done_vld ==1):
            print("Error: reg_fifo_cnt",reg_fifo_cnt)
            raise("Error,pru2cnt_rd_done_vld and pru_fsm_done_vld is 1 at one time!")

        return [
                ## define output of pru module
                ## to ctrl
                pru2ctrl_rd_done_vld_o,
                ## to out
                pru2output_data_vld,
                pru2output_data]
    
    def pru_without_prefetch_func(self, ## without prefetch func for ablation experiment
                 ## input port 
                 
                 ## from cntu
                 cnt2pru_rd_vld_i,  ## 2f
                 cnt2pru_rd_addr_i,
                 cnt2pru_rd_data_i 
                 ):
        ## read all regs
        reg_fsm_done_flag   = self.pru_reg_fsm_done_flag  .get_reg_q()
        reg_cnt_rd_data_vld = self.pru_reg_cnt_rd_data_vld.get_reg_q()
        reg_cnt_rd_data     = self.pru_reg_cnt_rd_data    .get_reg_q()
        reg_cnt_rd_data_idx = self.pru_reg_cnt_rd_data_idx.get_reg_q() 
        reg_cnt_num         = self.pru_reg_cnt_num        .get_reg_q()

        ## rd data from registerfile(reg_cnt_rd_data) and output data
        cnt_rd_bk_data          = reg_cnt_rd_data[reg_cnt_rd_data_idx]
        cnt_rd_bk_data_nzero_en = (cnt_rd_bk_data != 0)

        pru2output_data_vld   = (reg_cnt_rd_data_vld ==1) & (cnt_rd_bk_data_nzero_en ==1)
        pru2output_data       = reg_cnt_num
        
        pru2ctrl_rd_done_vld_o = reg_fsm_done_flag & reg_cnt_rd_data_vld & (reg_cnt_rd_data_idx==(const.SORT_FUC_BK_NUM-1)) & \
                                 ((cnt_rd_bk_data == 1) & (pru2output_data_vld==1) | (cnt_rd_bk_data == 0))


        reg_cnt_rd_data_idx_upd_en = (reg_cnt_rd_data_vld ==1) & ((cnt_rd_bk_data == 0)|((cnt_rd_bk_data == 1) & (pru2output_data_vld==1))) | (pru2ctrl_rd_done_vld_o==1)
        reg_cnt_rd_data_vld_clr_en = (reg_cnt_rd_data_vld ==1) & (reg_cnt_rd_data_idx ==(const.SORT_FUC_BK_NUM-1)) & \
                                     ((cnt_rd_bk_data == 1) & (pru2output_data_vld==1) | (cnt_rd_bk_data == 0))
        reg_cnt_rd_data_vld_upd_en = (reg_cnt_rd_data_vld_clr_en==1) | (cnt2pru_rd_vld_i == 1)
        reg_cnt_rd_data_upd_en     = (cnt2pru_rd_vld_i ==1)|(pru2output_data_vld==1)
        
        reg_cnt_rd_data_idx_d      = utils.adder_under_bitlimit(reg_cnt_rd_data_idx, 1, const.SORT_FUC_BK_DEPTH_WIDTH)

        reg_cnt_rd_data_d = reg_cnt_rd_data
        if(cnt2pru_rd_vld_i == 1) :
            reg_cnt_rd_data_d = cnt2pru_rd_data_i
        elif(pru2output_data_vld == 1):
            reg_cnt_rd_data_d[reg_cnt_rd_data_idx] = reg_cnt_rd_data_d[reg_cnt_rd_data_idx] -1
        
        if(pru2ctrl_rd_done_vld_o):
            reg_cnt_num_d = const.SORT_FUC_MAX_NUM-1
        else:
            reg_cnt_num_d = reg_cnt_num -1

        self.pru_reg_cnt_rd_data_vld.set_reg_d_with_en(reg_cnt_rd_data_vld_upd_en, cnt2pru_rd_vld_i)
        self.pru_reg_cnt_rd_data    .set_reg_d_with_en(reg_cnt_rd_data_upd_en    , reg_cnt_rd_data_d)
        self.pru_reg_cnt_rd_data_idx.set_reg_d_with_en(reg_cnt_rd_data_idx_upd_en, reg_cnt_rd_data_idx_d)
        self.pru_reg_cnt_num        .set_reg_d_with_en(reg_cnt_rd_data_idx_upd_en, reg_cnt_num_d)    

        self.pru_reg_fsm_done_flag  .set_reg_d_with_en(((self.pru_fsm_done_vld==1)|(pru2ctrl_rd_done_vld_o==1)),self.pru_fsm_done_vld)

        ## assert
        if((reg_cnt_rd_data_vld ==1) & (cnt2pru_rd_vld_i == 1)):
           raise("Error : without prefetch - reg_cnt_data_vld rd and wr at same time ")
        if((cnt2pru_rd_vld_i ==1) & (pru2output_data_vld==1)):
            raise("Error : without prefetch - reg_cnt_rd_data rd and wr at same time ")

        
        return [
                ## define output of pru module
                ## to ctrl
                pru2ctrl_rd_done_vld_o,
                ## to out
                pru2output_data_vld,
                pru2output_data]