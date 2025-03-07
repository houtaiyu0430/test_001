module newton_sqrt (
    input wire [31:0] number, // 输入的浮点数，IEEE 754格式
    output reg [31:0] result // 计算结果，IEEE 754格式
);

    reg [31:0] x; // 当前迭代值
    reg [31:0] y; // 上一次迭代值
    reg [31:0] half; // number 的一半
    integer i;

    initial begin
        x = 32'h3f800000; // 初始值为1.0，IEEE 754格式
        half = {number[31], number[30:23] - 1, number[22:0]};
    end

    always @(*) begin
        y = x;
        for (i = 0; i < 10; i = i + 1) begin
            y = x;
            x = x * (32'h3fc00000 - (half * x * x)); // 迭代公式
        end
        result = x;
    end

endmodule
