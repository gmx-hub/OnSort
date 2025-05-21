
//SORT DEFINE

`define SORT_FUC_MAX_NUM           8192
`define SORT_FUC_BK_NUM            8
`define SORT_FUC_PREFETCH_EN       1
`define SORT_PERF_PREFETCH_DEPTH   16
`define SORT_PERF_SBU_TILE_NUM     256
`define SORT_FUC_ZERO_NUM          0
`define SORT_PERF_PARALLEL_OUT_NUM 4     // only support 1/2/4

`define SORT_FUC_REG_EN            1

`define SORT_FUC_REPEAT_NUM        `SORT_FUC_MAX_NUM*2