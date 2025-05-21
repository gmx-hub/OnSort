`include "../../define/sort_define.v"

module tb_module1;
    parameter DATA_WIDTH = $clog2(`SORT_FUC_MAX_NUM);
    parameter ODER_EN    = 1;
    parameter ARRAY_SIZE = `SORT_FUC_MAX_NUM;
    parameter MIN_VALUE  = {DATA_WIDTH{1'b0}};
    parameter MAX_VALUE  = `SORT_FUC_MAX_NUM;
    parameter OUT_PORT   = `SORT_PERF_PARALLEL_OUT_NUM;
    
    
    reg  [DATA_WIDTH-1:0] rand_array [0:ARRAY_SIZE-1];
    reg  [DATA_WIDTH-1:0] sorted_array [0:ARRAY_SIZE-1];
    reg  [DATA_WIDTH-1:0] output_array [0:ARRAY_SIZE-1];

    reg                   data_in_vld;
    reg                   data_in_done_vld;
    reg                   input_config_mode_i;
    reg  [DATA_WIDTH-1:0] data_in;

    reg  [OUT_PORT  -1:0] data_out_vld;
    reg                   data_out_done_vld;    
    wire [OUT_PORT*DATA_WIDTH-1:0] data_out;

    reg  [DATA_WIDTH-1:0] temp;
    reg  clk,rst;

    reg  [31:0 ]cycles;

    integer  i;
    integer  j;
    int seed;
    integer in_index;
    integer out_index;

SORT_TOP U_SORT_TOP
(
.clk                        (clk                  ),
.rst                        (rst                  ),

.input_data_vld_i           (data_in_vld          ),
.input_data_i               (data_in              ),
.input_data_done_vld_i      (data_in_done_vld     ),
.input_config_mode_i        (input_config_mode_i  ),

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
        
        for (i=0; i<ARRAY_SIZE; i=i+1) begin
            rand_array[i] = $urandom_range(MIN_VALUE, MAX_VALUE);
            //rand_array[i] = 1;
            if (rand_array[i]<MIN_VALUE | rand_array[i]>MAX_VALUE  ) begin
                $display("Randomization failed at index %0d!", i);
                $finish;
            end
        end
        
        for (i=0; i<ARRAY_SIZE; i=i+1) begin
            sorted_array[i] = rand_array[i];
        end
        // sorting

        for (i=0; i<ARRAY_SIZE-1; i=i+1) begin
            for (j=0; j<ARRAY_SIZE-i-1; j=j+1) begin
                if (sorted_array[j] > sorted_array[j+1]) begin
                    temp = sorted_array[j];
                    sorted_array[j]   = sorted_array[j+1];
                    sorted_array[j+1] = temp;
                end
            end
        end

        if (ODER_EN==1) begin
            for (i = 0; i < ARRAY_SIZE/2; i = i+1) begin
                temp = sorted_array[i];
                sorted_array[i] = sorted_array[ARRAY_SIZE-i-1];
                sorted_array[ARRAY_SIZE-i-1] = temp;
            end        
        end
        
        // print unsorted data and sorted data
        $display("Original Random Array:");
        for (i=0; i<ARRAY_SIZE; i=i+1) begin
            $display("rand_array[%0d] = %0d", i, rand_array[i]);
        end
        
        $display("Sorted Array:");
        for (i=0; i<ARRAY_SIZE; i=i+1) begin
            $display("sorted_array[%0d] = %0d", i, sorted_array[i]);
        end
        
        #10;
        rst = 1;
        in_index  = 0;
        out_index = 0;
        cycles    = 1;
        // input data to ONSORT
        while ( ((in_index < ARRAY_SIZE) || (out_index < ARRAY_SIZE)) || ~data_out_done_vld ) begin            
            @(posedge clk);
            cycles = cycles +1;
            $display("Cycle num: %0d",cycles);
            if (in_index < ARRAY_SIZE-1) begin
                data_in = rand_array[in_index];
                data_in_vld = 1;
                data_in_done_vld = 0;
                in_index = in_index +1;
            end else if (in_index == ARRAY_SIZE-1) begin
                data_in = rand_array[in_index];
                data_in_vld = 1;
                data_in_done_vld = 1;
                in_index = in_index +1;
            end else begin
                data_in_vld = 0;
                data_in_done_vld =0 ;
            end
            for (i=0; i<OUT_PORT; i=i+1) begin 
                if (data_out_vld[i] ) begin
                    for (j=0; j<DATA_WIDTH; j=j+1) begin 
                        output_array[out_index][j] = data_out[i*DATA_WIDTH +j];
                    end
                    $display("Output index %0d: expected %0d, got %0d", out_index, sorted_array[out_index], output_array[out_index]);
                    if (output_array[out_index] !== sorted_array[out_index]) begin
                        //$display("Output index %0d: expected %0d, got %0d", out_index, sorted_array[out_index], output_array[out_index]);
                        $finish;
                    end
                    out_index = out_index +1;
                end
            end
        end
        
        $display("Output Array:");
        for (i=0; i<ARRAY_SIZE; i=i+1) begin
            $display("output_array[%0d] = %0d", i, output_array[i]);
        end

        // compare OnSort output
        for (integer i = 0; i < ARRAY_SIZE; i = i + 1) begin
            if (output_array[i] !== sorted_array[i]) begin
                $display("Mismatch at index %0d: expected %0d, got %0d", i, sorted_array[i], output_array[i]);
                $finish;
            end
        end
        
        $display("Test passed! All outputs match the sorted array.");
        $display("Cycle num: %0d",(cycles-2));
        $finish;
    end

    
endmodule

