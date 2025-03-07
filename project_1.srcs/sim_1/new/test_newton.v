`timescale 1ns / 1ps

module test_newton_sqrt;

    // ����
    reg [31:0] number;
    real accuracy_threshold;

    // ���
    wire [31:0] result;

    // �ڲ�����
    integer start_time;
    integer end_time;
    integer elapsed_time;
    real actual_value;
    real computed_value;
    real previous_computed_value;
    real relative_error;
    reg done;  // ��������������ѭ���˳�

    // ʵ����������ģ��
    newton_sqrt uut (
        .number(number),
        .result(result)
    );

    initial begin
        // ��ʼ����������
        number = 32'h40800000; // Ĭ��ֵ4.0��IEEE 754��ʽ
        accuracy_threshold = 0.005; // ������ֵ0.5%

        // ��ʼ������
        previous_computed_value = 0.0;

        // �����ﵽָ�����������ʱ��
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
                done = 1;  // ����doneΪ1���˳�ѭ��
            end
            previous_computed_value = computed_value;
            #1; // �ȴ�1��ʱ�䵥λ
        end

        // ��ʾ���
        $display("������ֵ: %f", $bitstoreal(number));
        $display("����ƽ�������: %f", computed_value);
        $display("ʵ��ֵ: %f", actual_value);
        $display("������: %f", relative_error);
        $display("����ʱ��: %0d ns", elapsed_time);

        // ��������
        $finish;
    end
      
endmodule
