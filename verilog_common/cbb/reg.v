

module CBB_REG #( 
             parameter  WIDTH = 8,
             parameter  INIT_VAL= 0)
(
    input                    clk,
    input                    rst,
 
    input  wire [WIDTH-1 :0] reg_d,

    output wire [WIDTH-1 :0] reg_q
);

reg [WIDTH-1: 0] data;

always @ (posedge clk or negedge rst) begin 
    if (!rst)
        data <= INIT_VAL;
    else 
        data <= reg_d;
end

assign reg_q = data;


endmodule

//CBB_REG #(.WIDTH(),.INIT_VAL())  (.clk(),.rst(),.reg_d(),.reg_q());