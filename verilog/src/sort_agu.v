

module SORT_AGU #( 
                  parameter  SORT_FUC_MAX_NUM         = `SORT_FUC_MAX_NUM        ,
                  parameter  SORT_FUC_BK_NUM          = `SORT_FUC_BK_NUM         ,
                  parameter  SORT_PERF_SBU_TILE_NUM   = `SORT_PERF_SBU_TILE_NUM  ,

                  parameter  SORT_FUC_CNT_MEM_DEPTH   = (SORT_FUC_MAX_NUM / SORT_FUC_BK_NUM),
                  parameter  SORT_FUC_CNT_MEM_DEPTH_W = $clog2(SORT_FUC_CNT_MEM_DEPTH),
                  parameter  SORT_FUC_DATA_W          = $clog2(SORT_FUC_MAX_NUM),
                  parameter  SORT_FUC_SBU_TILE_W      = $clog2(SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_PERF_SBU_NUM        = (SORT_FUC_MAX_NUM) / (SORT_PERF_SBU_TILE_NUM),
                  parameter  SORT_FUC_SBU_ADDR_W      = $clog2(SORT_PERF_SBU_NUM),
                  parameter  SORT_FUC_BK_DEPTH_W      = $clog2(SORT_FUC_BK_NUM)  )
(
    input  wire                                   agu_data_vld_i   ,
    input  wire [SORT_FUC_DATA_W            -1:0] agu_data_i       ,

    output wire                                   agu2sbu_vld_o    , 
    output wire [SORT_FUC_SBU_ADDR_W        -1:0] agu2sbu_addr_o   , 
    output wire [SORT_FUC_SBU_TILE_W        -1:0] agu2sbu_id_o     ,

    output wire                                   agu2cnt_vld_o    , 
    output wire [SORT_FUC_CNT_MEM_DEPTH_W   -1:0] agu2cnt_addr_o   , 
    output wire [SORT_FUC_BK_DEPTH_W        -1:0] agu2cnt_bankid_o
);

assign agu2sbu_vld_o    = agu_data_vld_i;
assign agu2sbu_addr_o   = agu_data_i[SORT_FUC_DATA_W    -1    :SORT_FUC_SBU_TILE_W  ];
assign agu2sbu_id_o     = agu_data_i[SORT_FUC_SBU_TILE_W-1    :0                    ];

assign agu2cnt_vld_o    = agu_data_vld_i;
assign agu2cnt_addr_o   = agu_data_i[SORT_FUC_DATA_W    -1    :SORT_FUC_BK_DEPTH_W  ];
assign agu2cnt_bankid_o = agu_data_i[SORT_FUC_BK_DEPTH_W-1    :0                    ];


endmodule

