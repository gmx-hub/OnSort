# OnSort: An O(n) Comparison-Free Sorter for Large-Scale Dataset with Parallel Prefetching and Sparse-Aware Mechanism
This repository contains the code for [OnSort: An O(n) Comparison-Free Sorter for Large-Scale Dataset with Parallel Prefetching and Sparse-Aware Mechanism](https:) (TCAS-II).


## Abstract
This paper proposes OnSort, a parallel comparison-free sorting architecture with O(n) time complexity, utilizing the SRAM structure to support large-scale datasets efficiently. The performance of existing comparison-free sorters is limited by uneven value distribution and variable element numbers. To address these issues, we introduce a parallel prefetching strategy to accelerate the indexing process and a sparse-aware mechanism to narrow the indexing search range. Furthermore, OnSort implements streaming execution through a pipelined design, thereby optimizing the previously overlooked latency of the counting phase. Experimental results show that, under the configuration of sorting 65,536 16-bit data elements, OnSort achieves a 1.97x speedup and a 22.6x throughput-to-area ratio compared to the existing design.

## Note
Due to property restrictions, we are unable to include the SRAM .lib and .db files in the open-source repository. To ensure functional correctness, the hardware code uses registers as a substitute for SRAM. To reproduce the frequency, power, and area reported in the paper, you need to generate the SRAM libraries using a memory compiler, replace the SRAM instances in sort_dp_bank_wrap.v, and set SORT_FUC_REG_EN to 0 in the sort_define file.


## Details and How to Run
RE Simulator:
```sh
cd simulator/test/
./run_test.sh
```

HT Simulator:
```sh
cd simulator_high_performance/test/
./run_test.sh
```

To modify the experimental settings, such as the maximum number of elements to sort or other hardware parameters, please edit simulator(simulator_high_performance)/top/const.py.

RE Verilog:  
test_file: verilog/test/test_sort_top.sv  
filelist: verilog/sort_filelist.f
```sh
vlog -f sort_filelist.f
vsim -f sort_filelist.f
```

HT Verilog:  
test_file: verilog_high_performance/test/test_sort_top.sv  
filelist: verilog_high_performance/sort_filelist.f
```sh
vlog -f sort_filelist.f
vsim -f sort_filelist.f
```


To modify the experimental settings, such as the maximum number of elements to sort or other hardware parameters, please edit verilog(verilog_high_performance)/sort_define.v

Note: 
The Verilog code has not undergone industry-grade testing and may contain some bugs.
