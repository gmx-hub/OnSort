`include "../../define/sort_define.v"

module tb_module1;
    parameter DATA_WIDTH = $clog2(`SORT_FUC_MAX_NUM);
    parameter ODER_EN    = 1;
    parameter ARRAY_SIZE = `SORT_FUC_MAX_NUM;
    parameter MIN_VALUE  = {DATA_WIDTH{1'b0}};
    parameter MAX_VALUE  = `SORT_FUC_MAX_NUM;
    parameter OUT_PORT   = `SORT_PERF_PARALLEL_OUT_NUM;
    
    parameter TSK_NUM = 3;
    
    reg  [DATA_WIDTH-1:0] rand_array   [0:TSK_NUM-1][0:ARRAY_SIZE-1];
    reg  [DATA_WIDTH-1:0] sorted_array [0:TSK_NUM-1][0:ARRAY_SIZE-1];
    reg  [DATA_WIDTH-1:0] output_array [0:TSK_NUM-1][0:ARRAY_SIZE-1];

    reg                   data_in_vld;
    reg                   data_in_done_vld;
    reg                   input_config_mode_i;
    reg                   ctrl2input_rdy_o   ;
    reg  [DATA_WIDTH-1:0] data_in;

    reg  [OUT_PORT  -1:0] data_out_vld;
    reg                   data_out_done_vld;    
    wire [OUT_PORT*DATA_WIDTH-1:0] data_out;

    reg  [DATA_WIDTH-1:0] temp;
    reg  clk,rst;

    reg  [31:0 ]cycles;

    integer  i;
    integer  j;
    integer  k;
    integer in_index;
    integer out_index;
    integer itsk_index;
    integer otsk_index;
SORT_TOP U_SORT_TOP
(
.clk                        (clk                  ),
.rst                        (rst                  ),

.input_data_vld_i           (data_in_vld          ),
.input_data_i               (data_in              ),
.input_data_done_vld_i      (data_in_done_vld     ),
.input_config_mode_i        (input_config_mode_i  ),

.ctrl2input_rdy_o           (ctrl2input_rdy_o     ),

.output_vld                 (data_out_vld         ), 
.output_data                (data_out             ), 
.output_done_vld            (data_out_done_vld    )
);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end
    
    // generate rdm data
    initial begin
        data_in = 0;
        data_in_vld = 0;
        data_in_done_vld = 0; 
        input_config_mode_i = ODER_EN;
        rst = 0;
        
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                //rand_array[i][j] = 1;
                rand_array[i][j] = j;
                //rand_array[i][j] = $urandom_range(MIN_VALUE, MAX_VALUE);
                if (rand_array[i][j]<MIN_VALUE | rand_array[i][j]>MAX_VALUE  ) begin
                    $display("Randomization failed at index %0d,%0d!", i,j);
                    $finish;
                end
            end
        end

        $display("Original Random Array:");
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                $display("rand_array[%0d][%0d] = %0d", i,j, rand_array[i][j]);
            end
        end
        
        // Sorting
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                sorted_array[i][j] = rand_array[i][j];
            end
        end

        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE-1; j=j+1) begin
                for (k=0; k<ARRAY_SIZE-j-1; k=k+1) begin
                    if (sorted_array[i][k] > sorted_array[i][k+1]) begin
                        temp = sorted_array[i][k];
                        sorted_array[i][k]   = sorted_array[i][k+1];
                        sorted_array[i][k+1] = temp;
                    end
                end
            end
        end

        if (ODER_EN==1) begin
            for (i=0; i<TSK_NUM; i=i+1) begin
                for (j = 0; j < ARRAY_SIZE/2; j = j+1) begin
                    temp = sorted_array[i][j];
                    sorted_array[i][j] = sorted_array[i][ARRAY_SIZE-j-1];
                    sorted_array[i][ARRAY_SIZE-j-1] = temp;
                end   
            end     
        end
        
        // print unsorted data and sort data
        $display("Original Random Array:");
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                $display("rand_array[%0d][%0d] = %0d", i,j, rand_array[i][j]);
            end
        end
        
        $display("Sorted Array:");
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                $display("sorted_array[%0d][%d] = %0d", i,j, sorted_array[i][j]);
            end
        end
        
        #10;
        rst = 1;
        itsk_index = 0;
        otsk_index = 0;
        in_index  = 0;
        out_index = 0;
        cycles    = 0;
        // input unsorted data to OnSort

        while ( (otsk_index < TSK_NUM) ) begin            
            @(posedge clk);
            cycles = cycles +1;
            if ((itsk_index<TSK_NUM) & (in_index < ARRAY_SIZE-1) & ctrl2input_rdy_o ) begin
                data_in = rand_array[itsk_index][in_index];
                data_in_vld = 1;
                data_in_done_vld = 0;
                in_index = in_index +1;
            end else if ((itsk_index<TSK_NUM) & (in_index == ARRAY_SIZE-1) & ctrl2input_rdy_o ) begin
                data_in = rand_array[itsk_index][in_index];
                data_in_vld = 1;
                data_in_done_vld = 1;
                in_index = 0;
                itsk_index = itsk_index + 1;
            end else begin
                data_in_vld = 0;
                data_in_done_vld =0 ;
            end
            
            for (i=0; i<OUT_PORT; i=i+1) begin 
                if (data_out_vld[i] ) begin
                    for (j=0; j<DATA_WIDTH; j=j+1) begin 
                        output_array[otsk_index][out_index][j] = data_out[i*DATA_WIDTH +j];
                    end
                    //$display("Output index %0d: expected %0d, got %0d", out_index, sorted_array[out_index], output_array[out_index]);
                    if (output_array[otsk_index][out_index] !== sorted_array[otsk_index][out_index]) begin
                        $display("Output task %0d index %0d: expected %0d, got %0d", otsk_index ,out_index, sorted_array[otsk_index][out_index], output_array[otsk_index][out_index]);
                        $finish;
                    end
                    out_index = out_index +1;
                end
            end


            if (data_out_done_vld) begin
                otsk_index = otsk_index + 1;
                out_index  = 0;
            end
        end
        
        $display("Output Array:");
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j=0; j<ARRAY_SIZE; j=j+1) begin
                $display("output_array[%0d][%0d] = %0d", i,j, output_array[i][j]);
            end
        end

        // compare OnSort output and right value
        for (i=0; i<TSK_NUM; i=i+1) begin
            for (j = 0; j < ARRAY_SIZE; j = j + 1) begin
                if (output_array[i][j] !== sorted_array[i][j]) begin
                    $display("Mismatch at index %0d,%0d: expected %0d, got %0d", i,j, sorted_array[i][j], output_array[i][j]);
                    $finish;
                end
            end
        end
        
        $display("Test passed! All outputs match the sorted array.");
        $display("Cycle num: %0d",cycles-1);
        $finish;
    end

    
endmodule

