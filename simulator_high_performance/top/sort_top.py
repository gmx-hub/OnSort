import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np
import pdb

from simulator_common.cbb.reg                          import reg
from simulator_high_performance.top.const              import const
from simulator_common.utils.logging_config             import logging_config
from simulator_high_performance.src.sort_cnt_unit      import sort_cnt_unit
from simulator_high_performance.src.sort_agu           import sort_agu
from simulator_high_performance.src.sort_ctrl          import sort_ctrl
from simulator_high_performance.src.sort_pru           import sort_pru
from simulator_high_performance.src.sort_sbu           import sort_sbu


class sort_highperformance_top:
    def __init__(self):
        ## define submodule
        self.agu        = sort_agu()
        self.cnt_unit0  = sort_cnt_unit()
        self.cnt_unit1  = sort_cnt_unit()
        self.ctrl       = sort_ctrl()
        self.pru        = sort_pru() 

        ## wire
        self.ctrl2input_rdy = 1


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

        input_data_vld = (input_data_vld_i==1) & (self.ctrl2input_rdy==1)
        
        ## generate read unit start signal
        ctrl2pru_start_vld_o,self.ctrl2input_rdy, ctrl_rd_sel, ctrl_wr_sel = self.ctrl.sort_ctrl_wr_state_func(ctrl_input_done_vld_i=input_data_done_vld_i)

        ## input data -> cnt mem/sbu addr 
        [
            agu2pru_sbu_vld_o,
            agu2pru_sbu_addr_o,
            agu2sbu_sbu_id_o,

            agu2cnt_vld_o,
            agu2cnt_addr_o,
            agu2cnt_bankid_o
         ] = self.agu.agu_func(
                agu_vld_i  = input_data_vld,
                agu_data_i = input_data_i)
        
        ## get data from cnt_unit(cnt mem) to read unit
        agu2cnt1_vld = agu2cnt_vld_o if (ctrl_wr_sel==1) else 0
        agu2cnt0_vld = agu2cnt_vld_o if (ctrl_wr_sel==0) else 0       

        [
            cnt2pru0_rd_vld_o,
            cnt2pru0_rd_1f_vld_o,
            cnt2pru0_rd_addr_o,
            cnt2pru0_rd_data_o,
            cntu2ctrl0_wr_done_vld_o] = self.cnt_unit0.cnt_unit_get_state(agu2cnt_vld_i = agu2cnt0_vld)
        
        [
            cnt2pru1_rd_vld_o,
            cnt2pru1_rd_1f_vld_o,
            cnt2pru1_rd_addr_o,
            cnt2pru1_rd_data_o,
            cntu2ctrl1_wr_done_vld_o] = self.cnt_unit1.cnt_unit_get_state(agu2cnt_vld_i = agu2cnt1_vld)
        
        cnt2pru_rd_vld_o        = cnt2pru1_rd_vld_o    if (ctrl_rd_sel == 1) else cnt2pru0_rd_vld_o
        cnt2pru_rd_1f_vld_o     = cnt2pru1_rd_1f_vld_o if (ctrl_rd_sel == 1) else cnt2pru0_rd_1f_vld_o
        cnt2pru_rd_addr_o       = cnt2pru1_rd_addr_o   if (ctrl_rd_sel == 1) else cnt2pru0_rd_addr_o
        cnt2pru_rd_data_o       = cnt2pru1_rd_data_o   if (ctrl_rd_sel == 1) else cnt2pru0_rd_data_o
        cntu2ctrl_wr_done_vld_o = cntu2ctrl1_wr_done_vld_o if (ctrl_rd_sel==1) else cntu2ctrl0_wr_done_vld_o

        ## generate addr from pru to cnt_unit
        if(const.SORT_FUC_PREFETCH_EN ==1): ## use prefetch func to improve perfermance
            [
                pru2cnt_rd_vld_o,
                pru2cnt_rd_addr_o
            ] = self.pru.pru_with_prefetch_generate_addr(
                                        ctrl_wr_sel               = ctrl_wr_sel,
                                        ctrl_rd_sel               = ctrl_rd_sel,
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
        pru2cnt0_rd_vld  = pru2cnt_rd_vld_o  if(ctrl_rd_sel == 0) else 0
        pru2cnt0_rd_addr = pru2cnt_rd_addr_o if(ctrl_rd_sel == 0) else 0
        agu2cnt0_vld     = agu2cnt_vld_o     if(ctrl_wr_sel == 0) else 0
        agu2cnt0_addr    = agu2cnt_addr_o    if(ctrl_wr_sel == 0) else 0
        agu2cnt0_bankid  = agu2cnt_bankid_o  if(ctrl_wr_sel == 0) else 0

        pru2cnt1_rd_vld  = pru2cnt_rd_vld_o  if(ctrl_rd_sel == 1) else 0
        pru2cnt1_rd_addr = pru2cnt_rd_addr_o if(ctrl_rd_sel == 1) else 0
        agu2cnt1_vld     = agu2cnt_vld_o     if(ctrl_wr_sel == 1) else 0
        agu2cnt1_addr    = agu2cnt_addr_o    if(ctrl_wr_sel == 1) else 0
        agu2cnt1_bankid  = agu2cnt_bankid_o  if(ctrl_wr_sel == 1) else 0

        if ((pru2cnt0_rd_vld & agu2cnt0_vld) == 1):
            pdb.set_trace()
            raise("Error: pru2cnt_rd_vld and agu2cnt_vld is same at one time" )
        
        if ((pru2cnt1_rd_vld & agu2cnt1_vld) == 1):
            pdb.set_trace()
            raise("Error: pru2cnt_rd_vld and agu2cnt_vld is same at one time" )        

        self.cnt_unit0.cnt_unit_fuc(
            pru2cnt_rd_vld_i  = pru2cnt0_rd_vld  ,
            pru2cnt_rd_addr_i = pru2cnt0_rd_addr ,
            agu2cnt_vld_i     = agu2cnt0_vld     ,
            agu2cnt_addr_i    = agu2cnt0_addr    ,
            agu2cnt_bankid_i  = agu2cnt0_bankid  )

        self.cnt_unit1.cnt_unit_fuc(
            pru2cnt_rd_vld_i  = pru2cnt1_rd_vld  ,
            pru2cnt_rd_addr_i = pru2cnt1_rd_addr ,
            agu2cnt_vld_i     = agu2cnt1_vld     ,
            agu2cnt_addr_i    = agu2cnt1_addr    ,
            agu2cnt_bankid_i  = agu2cnt1_bankid  )

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
                       ctrl_vld_i                  = input_data_vld,
                       ctrl_input_done_vld_i       = input_data_done_vld_i,
                       cntu2ctrl_wr_done_vld_i     = cntu2ctrl_wr_done_vld_o,
                       pru2ctrl_rd_done_vld_i      = pru2ctrl_rd_done_vld_o)


        return [pru2output_data_vld,pru2output_data,pru2ctrl_rd_done_vld_o,self.ctrl2input_rdy]

    def run_one_cycle(self,
                      ## input 
                      input_data_vld_i,
                      input_data_i,
                      input_data_done_vld_i,
                      ## input config
                      input_config_mode_i=1):
        
        output_vld, output_data, output_done_vld, ctrl2input_rdy = self.sort_top_func(input_data_vld_i      = input_data_vld_i,
                                                                      input_data_i          = input_data_i,
                                                                      input_data_done_vld_i = input_data_done_vld_i,
                                                                      input_config_mode_i   = input_config_mode_i)
        
        return [output_vld, output_data, output_done_vld,ctrl2input_rdy]
    
    def endsim_check(self,input_config_mode_i):
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
            print(self.pru.pru_fsm.pru_reg_prefetch_state   .get_reg_q())
            print(self.pru.pru_fsm.pru_reg_prefetch_state   .get_reg_q())
            print(self.pru.pru_fsm.pru_reg_nprefetch_state  .get_reg_q())
            print(self.pru.pru_fsm.pru_reg_nprefetch_mem_cnt.get_reg_q())
            raise("Error-pru-FSM: after done have vld != 0 !")








        




