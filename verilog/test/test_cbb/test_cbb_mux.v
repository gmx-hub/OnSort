`include "../../cbb/mux.v"

module tb_param_mux_onehot;

    parameter DATA_WIDTH = 8;
    parameter NUM_INPUTS = 4;

    reg [DATA_WIDTH*NUM_INPUTS-1:0] data_in;
    reg [NUM_INPUTS-1:0] sel;
    wire [DATA_WIDTH-1:0] data_out;

    // Instantiate the param_mux_onehot module
    CBB_MUX #(.WIDTH(DATA_WIDTH), .N(NUM_INPUTS)) uut (
        .data_in(data_in),
        .sel(sel),
        .data_out(data_out)
    );

    initial begin
        // Initialize inputs
        data_in = {8'b00001000, 8'b00000100, 8'b00000010, 8'b00000001};
        
        // Test different one-hot select inputs
        sel = 4'b0001; #10;
        sel = 4'b0010; #10;
        sel = 4'b0100; #10;
        sel = 4'b1000; #10;

        // End the simulation
        $finish;
    end

    // Monitor changes in the input and output
    initial begin
        $monitor("At time %t, sel = %b, data_out = %b", $time, sel, data_out);
    end

endmodule