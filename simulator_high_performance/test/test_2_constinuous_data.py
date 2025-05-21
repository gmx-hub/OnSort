import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import numpy as np

from simulator_high_performance.top.const      import const

from simulator_high_performance.top.sort_top   import sort_highperformance_top

import simulator_common.utils.utils as utils


data_type = sys.argv[1]
task_num  = int(sys.argv[2])
size    = int(const.SORT_FUC_MAX_NUM / int(sys.argv[3]))

file_path = f"{const.test_hardware_type}_dn{const.SORT_FUC_MAX_NUM}_bk{const.SORT_FUC_BK_NUM}_fifo{const.SORT_PERF_PREFETCH_DEPTH}_tile{const.SORT_PERF_SBU_TILE_NUM}_port{const.SORT_PERF_OUT_PARALLEL}_log_{data_type}.txt"


max_val = const.SORT_FUC_MAX_NUM
min_val = 0 

## generate data
seed                  = np.zeros(task_num,dtype=int)
input_data_i          = np.zeros((task_num,size),dtype=int)

for i in range(task_num):
    if (data_type == 'all1'):
        input_data_i[i]          = utils.generate_all1_integer_data(size=size)
    elif (data_type == 'rdm'):
        seed[i], input_data_i[i] = utils.generate_rdm_integer_data(size=size,max_val=max_val,min_val=min_val)
    elif (data_type == 'gs'):
        input_data_i[i] = utils.generate_gaussian_integer_data(num_samples=size, min_value=min_val, max_value=max_val)
    elif (data_type == 'best'):
        input_data_i[i]          = utils.generate_best_integer_data(size=size,max_val=max_val,min_val=min_val)
    else:
        raise("Dataset is not suppoted")

##
input_data_vld_i      = np.zeros((task_num,size),dtype=int)
input_data_done_vld_i = np.zeros((task_num,size),dtype=int)
input_config_mode_i   = np.zeros(task_num,dtype=int)
length                = np.zeros(task_num,dtype=int)
compare_result        = np.zeros(task_num,dtype=int)

## data 
for i in range(task_num):  
    input_data_vld_i[i]      = np.ones(size,dtype=int)
    input_data_done_vld_i[i] = np.zeros(size,dtype=int)
    input_data_done_vld_i[i][(size-1)] =1
    input_config_mode_i[i]   = 1
    
    length[i] = len(input_data_vld_i[i])


## 
sort = sort_highperformance_top()
sort_result   = np.zeros((task_num,size),dtype=int)
i = 0
j = 0
otsk = 0
oidx = 0
task_cycle = np.zeros(task_num,dtype=int)
cycle = 1
ctrl2input_rdy = 1
while True:
    if(i < task_num): 
        input_vld         = input_data_vld_i     [i][j] if j < length[i] else False
        input_data        = input_data_i         [i][j] if j < length[i] else 0
        input_done_vld    = input_data_done_vld_i[i][j] if j < length[i] else False
        input_config_mode = input_config_mode_i  [i]
    else:
        input_vld         = False
        input_data        = 0
        input_done_vld    = False
        input_config_mode = 1

    if(ctrl2input_rdy ==1):
        j = j + 1
    if(input_done_vld & ctrl2input_rdy) :
        i = i + 1
        j = 0

    output_vld, output_data, output_done_vld,ctrl2input_rdy  = sort.run_one_cycle(input_data_vld_i      = input_vld,
                                                                                  input_data_i          = input_data,
                                                                                  input_data_done_vld_i = input_done_vld,
                                                                                  input_config_mode_i   = input_config_mode)

    for port in range (const.SORT_PERF_OUT_PARALLEL):
        if(output_vld[port] ==1):
            sort_result[otsk][oidx] = output_data[port]
            oidx = oidx+1

    cycle = cycle + 1

    if(i == task_num):
        task_cycle[i-1] = task_cycle[i-1] + 1
    else:
        task_cycle[i] = task_cycle[i] + 1

    if((output_done_vld ==1)):
        sort.endsim_check(input_config_mode) 

        np_sort0      = np.sort(input_data_i[otsk])
        np_sort_data0 = np_sort0[::-1] if (input_config_mode_i[otsk]==1) else np_sort0
        
        compare_result[otsk] = np.array_equal(np_sort_data0,sort_result[otsk])
        if(compare_result[otsk] ==0):
            print("********Final resulet******")
            print("input_data_i:",input_data_i[otsk])
            print("np_sort_data:",np_sort_data0)
            print("sort_data   :",sort_result[otsk])
            print("compare result:",compare_result[otsk])
            print("seed",seed)    
            break

        otsk = otsk + 1
        oidx = 0
        if(otsk == task_num):
            break
    if (cycle == const.SORT_FUC_MAX_NUM*5*task_num):
        raise("Error: timeout!")
    
file=open(file_path,'a')

sys.stdout=file

print("High_throuthput")

print("Software parameter,div:",int(const.SORT_FUC_MAX_NUM/size),"data_type:",data_type,"task_num:",task_num)
print("Hardware parameter,MAX_NUM:",const.SORT_FUC_MAX_NUM,"PREFETCH_EN:",const.SORT_FUC_PREFETCH_EN,"BANK:",const.SORT_FUC_BK_NUM,"SBU_TILE_NUM:",const.SORT_PERF_SBU_TILE_NUM,"PORT:",const.SORT_PERF_OUT_PARALLEL)

print("task_cycle",task_cycle)
print("cycle=",cycle)  
print("avg_clk=",int(cycle/task_num))


if(np.all(compare_result==1)):
    print("####  compare Pass  ####:")
else:
    print("####  compare ERROR!!!!!!  ####:")

sys.stdout=sys.__stdout__
