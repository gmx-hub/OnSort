module CBB_MUX #(parameter WIDTH = 4, parameter N = 2)
  (
  input  wire [N       -1:0] sel,
  input  wire [WIDTH*N -1:0] data_in,
  output reg  [WIDTH   -1:0] data_out
);

    integer i;
    always @(*) begin
        data_out = {WIDTH{1'b0}};  // Default to zero
        for (i = 0; i < N; i = i + 1) begin
            if (sel[i]) begin
                data_out = data_in[i*WIDTH +: WIDTH];
            end
        end
    end

endmodule