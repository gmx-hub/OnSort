import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np
import pdb

from simulator_common.cbb.reg                import reg
from simulator.top.const                     import const
from simulator_common.utils.logging_config   import logging_config
from simulator.src.sort_cnt_unit             import sort_cnt_unit
from simulator.src.sort_agu                  import sort_agu
from simulator.src.sort_ctrl                 import sort_ctrl
from simulator.src.sort_pru                  import sort_pru
from simulator.src.sort_sbu                  import sort_sbu



class sort_top:
    def __init__(self):
        ## define submodule
        self.agu       = sort_agu()
        self.cnt_unit  = sort_cnt_unit()
        self.ctrl      = sort_ctrl()
        self.pru       = sort_pru() 



    def sort_top_func(self, 
                      ## input 
                      input_data_vld_i,
                      input_data_i,
                      input_data_done_vld_i,
                      ## input config
                      input_config_mode_i=1
                      ):

        ctrl_config_mode = input_config_mode_i
        if(ctrl_config_mode == 0):
            ctrl_config_oder_en = 0 ## if 1 , output from large to small. else 0, output from small to large
                                    ## Note if prefetch_en is 0, design can't support ctrl_config_oder_en=0
        elif(ctrl_config_mode == 1):
            ctrl_config_oder_en = 1

        ## input data -> cnt mem/sbu addr 
        [
            agu2pru_sbu_vld_o,
            agu2pru_sbu_addr_o,
            agu2sbu_sbu_id_o,

            agu2cnt_vld_o,
            agu2cnt_addr_o,
            agu2cnt_bankid_o
         ] = self.agu.agu_func(
                agu_vld_i  = input_data_vld_i,
                agu_data_i = input_data_i)
        
        ## get data from cnt_unit(cnt mem) to read unit
        [
            cnt2pru_rd_vld_o,
            cnt2pru_rd_1f_vld_o,
            cnt2pru_rd_addr_o,
            cnt2pru_rd_data_o,
            cntu2ctrl_wr_done_vld_o] = self.cnt_unit.cnt_unit_get_state(agu2cnt_vld_i = agu2cnt_vld_o)
    
        ## generate read unit start signal
        ctrl2pru_start_vld_o = self.ctrl.sort_ctrl_wr_state_func(cntu2ctrl_wr_done_vld_i = cntu2ctrl_wr_done_vld_o)

        ## generate addr from pru to cnt_unit
        if(const.SORT_FUC_PREFETCH_EN ==1): ## use prefetch func to improve perfermance
            [
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
            ] = self.pru.pru_with_prefetch_generate_addr(
                                        ctrl2pru_start_vld_i      = ctrl2pru_start_vld_o, 
                                        ctrl2pru_config_oder_en_i = ctrl_config_oder_en,
                                        agu2pru_sbu_wr_vld_i      = agu2pru_sbu_vld_o,
                                        agu2pru_sbu_wr_addr_i     = agu2pru_sbu_addr_o,
                                        cnt2pru_rd_1f_vld_i       = cnt2pru_rd_1f_vld_o, 
                                        cnt2pru_rd_vld_i          = cnt2pru_rd_vld_o)
        else:
            [
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
            ] = self.pru.pru_without_prefetch_generate_addr(
                                           cnt2pru_rd_1f_vld_i  = cnt2pru_rd_1f_vld_o, 
                                           cnt2pru_rd_vld_i     = cnt2pru_rd_vld_o   ,           
                                           ctrl2pru_start_vld_i = ctrl2pru_start_vld_o)
    
        ## cnt_unit(cnt mem) get the addr/data from agu and pru
        self.cnt_unit.cnt_unit_fuc(
            pru2cnt_rd_vld_i  = pru2cnt_rd_vld_o,
            pru2cnt_rd_addr_i = pru2cnt_rd_addr_o,
            agu2cnt_vld_i     = agu2cnt_vld_o,
            agu2cnt_addr_i    = agu2cnt_addr_o,
            agu2cnt_bankid_i  = agu2cnt_bankid_o)

        if(const.SORT_FUC_PREFETCH_EN ==1): ## use prefetch func to improve perfermance
            [
                pru2ctrl_rd_done_vld_o,
                pru2output_data_vld,
                pru2output_data] =  self.pru.pru_with_prefetch_func( 
                     ctrl2pru_config_oder_en_i = ctrl_config_oder_en,
                     cnt2pru_rd_vld_i          = cnt2pru_rd_vld_o, 
                     cnt2pru_rd_addr_i         = cnt2pru_rd_addr_o,
                     cnt2pru_rd_data_i         = cnt2pru_rd_data_o
                     )
        else:
            [
                pru2ctrl_rd_done_vld_o,
                pru2output_data_vld,
                pru2output_data] =  self.pru.pru_without_prefetch_func(
                     cnt2pru_rd_vld_i     = cnt2pru_rd_vld_o, 
                     cnt2pru_rd_addr_i    = cnt2pru_rd_addr_o,
                     cnt2pru_rd_data_i    = cnt2pru_rd_data_o
                     )

        self.ctrl.sort_ctrl_upd_state_func(
                       ctrl_vld_i                  = input_data_vld_i,
                       ctrl_input_done_vld_i       = input_data_done_vld_i,
                       cntu2ctrl_wr_done_vld_i     = cntu2ctrl_wr_done_vld_o,
                       pru2ctrl_rd_done_vld_i      = pru2ctrl_rd_done_vld_o)


        return [pru2output_data_vld,pru2output_data,pru2ctrl_rd_done_vld_o]

    def run_one_cycle(self,
                      ## input 
                      input_data_vld_i,
                      input_data_i,
                      input_data_done_vld_i,
                      ## input config
                      input_config_mode_i=1):
        
        output_vld, output_data, output_done_vld = self.sort_top_func(input_data_vld_i      = input_data_vld_i,
                                                                      input_data_i          = input_data_i,
                                                                      input_data_done_vld_i = input_data_done_vld_i,
                                                                      input_config_mode_i   = input_config_mode_i)
        
        return [output_vld, output_data, output_done_vld]
    
    def endsim_check(self,input_config_mode_i):
        if (np.array_equal(self.cnt_unit.cnt_mem.cnt_mem.mem,np.zeros((const.SORT_FUC_CNT_MEM_DEPTH, const.SORT_FUC_BK_NUM),dtype=int)) !=1):
           print("cnt_mem",self.cnt_unit.cnt_mem.cnt_mem.mem)
           raise("Error-CNTU: after done cnt_mem != 0 !")
        
        cntu_endsimcheck_en = (self.cnt_unit.cnt_reg_cnt_rd_1f_vld   .get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_pru_rd_1f_vld   .get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_addr_same_2f_vld.get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_pru_rd_2f_vld   .get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_cnt_rd_2f_vld   .get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_pru_rd_2f_vld   .get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_addr_same_3f_vld.get_reg_q() != 0) | \
                              (self.cnt_unit.cnt_reg_cnt_rd_3f_vld   .get_reg_q() != 0)   
        if (cntu_endsimcheck_en == 1):
            raise("Error-CNTU: after done have vld != 0 !")
        
        if ((self.ctrl.ctrl_reg_state.get_reg_q() !=0) | (self.ctrl.ctrl_reg_input_done_vld_1f.get_reg_q() !=0)):
            raise("Error-CTRL: after done have vld != 0 !")
 
        pru_fsm_endsimcheck_en = (self.pru.pru_fsm.pru_reg_prefetch_state   .get_reg_q()  != 0                                      ) | \
                                 (self.pru.pru_fsm.pru_reg_prefetch_state   .get_reg_q()  != 0                                      ) | \
                                 (self.pru.pru_fsm.pru_reg_nprefetch_state  .get_reg_q()  != 0                                      ) | \
                                 (self.pru.pru_fsm.pru_reg_nprefetch_mem_cnt.get_reg_q()  != const.SORT_FUC_CNT_MEM_DEPTH-1         )                                    
        
        if( input_config_mode_i==1):
            cnt_endsimcheck_en = (self.pru.pru_fsm.pru_reg_prefetch_sbu_cnt .get_reg_q()  != (const.SORT_PERF_SBU_NUM -1)) | \
                                 (self.pru.pru_fsm.pru_reg_prefetch_mem_cnt .get_reg_q()  != (const.SORT_FUC_SBU_TILE_CNT_MAX_NUM-1))
 
        else: 
            cnt_endsimcheck_en = (self.pru.pru_fsm.pru_reg_prefetch_sbu_cnt .get_reg_q()  != 0) | \
                                 (self.pru.pru_fsm.pru_reg_prefetch_mem_cnt .get_reg_q()  != 0) 

        if ((pru_fsm_endsimcheck_en == 1) | (cnt_endsimcheck_en ==1)):
            raise("Error-pru-FSM: after done have vld != 0 !")
        
        sbu_data_endsimcheck_en = np.array_equal(self.pru.pru_fsm.sbu.sbu_reg_sbu.get_reg_q(),np.zeros(const.SORT_PERF_SBU_NUM,dtype=int))

        if (sbu_data_endsimcheck_en !=1):
           print("Error-SBU: sbu=",self.pru.pru_fsm.sbu.sbu_reg_sbu.get_reg_q())
           raise("Error-SBU: after done sbu != 0 !")


    










        




