module newton_sqrt (
    input wire [31:0] number, // ����ĸ�������IEEE 754��ʽ
    output reg [31:0] result // ��������IEEE 754��ʽ
);

    reg [31:0] x; // ��ǰ����ֵ
    reg [31:0] y; // ��һ�ε���ֵ
    reg [31:0] half; // number ��һ��
    integer i;

    initial begin
        x = 32'h3f800000; // ��ʼֵΪ1.0��IEEE 754��ʽ
        half = {number[31], number[30:23] - 1, number[22:0]};
    end

    always @(*) begin
        y = x;
        for (i = 0; i < 10; i = i + 1) begin
            y = x;
            x = x * (32'h3fc00000 - (half * x * x)); // ������ʽ
        end
        result = x;
    end

endmodule
