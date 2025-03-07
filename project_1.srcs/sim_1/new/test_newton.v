`timescale 1ns / 1ps

module test_newton_sqrt;

    // 输入
    reg [31:0] number;
    real accuracy_threshold;

    // 输出
    wire [31:0] result;

    // 内部变量
    integer start_time;
    integer end_time;
    integer elapsed_time;
    real actual_value;
    real computed_value;
    real previous_computed_value;
    real relative_error;
    reg done;  // 布尔变量，控制循环退出

    // 实例化被测试模块
    newton_sqrt uut (
        .number(number),
        .result(result)
    );

    initial begin
        // 初始化输入数据
        number = 32'h40800000; // 默认值4.0，IEEE 754格式
        accuracy_threshold = 0.005; // 精度阈值0.5%

        // 初始化变量
        previous_computed_value = 0.0;

        // 测量达到指定精度所需的时间
        actual_value = 1.0 / $sqrt($bitstoreal(number));
        start_time = $time;
        done = 0;
        
        while (!done) begin
            computed_value = $bitstoreal(result);
            relative_error = (previous_computed_value - computed_value) / previous_computed_value;
            if (relative_error < 0) relative_error = -relative_error;
            if ((relative_error <= accuracy_threshold) && (relative_error != 0)) begin
                end_time = $time;
                elapsed_time = end_time - start_time;
                done = 1;  // 设置done为1，退出循环
            end
            previous_computed_value = computed_value;
            #1; // 等待1个时间单位
        end

        // 显示结果
        $display("输入数值: %f", $bitstoreal(number));
        $display("倒数平方根结果: %f", computed_value);
        $display("实际值: %f", actual_value);
        $display("相对误差: %f", relative_error);
        $display("运行时间: %0d ns", elapsed_time);

        // 结束仿真
        $finish;
    end
      
endmodule
