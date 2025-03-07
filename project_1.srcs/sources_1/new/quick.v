module fast_inverse_sqrt (
    input wire [31:0] number,
    output wire [31:0] result
);

    wire [31:0] i;
    wire [31:0] x2;
    wire [31:0] y;
    wire [31:0] magic;
    wire [31:0] new_y;
    wire [31:0] correction;

    assign x2 = {number[31], number[30:23] - 1, number[22:0]} >> 1;
    assign y = number;
    assign i = 32'h5f3759df - (y >> 1);
    assign magic = i;
    assign new_y = magic;
    assign correction = 32'h3fc00000 - (x2 * new_y * new_y);
    assign result = new_y * correction;

endmodule