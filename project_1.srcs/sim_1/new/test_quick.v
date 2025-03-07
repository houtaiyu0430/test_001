`timescale 1ns / 1ps

module test_fast_inverse_sqrt;

    // Inputs
    reg [31:0] number;
    real accuracy_threshold;

    // Outputs
    wire [31:0] result;

    // Internal variables for measuring time and accuracy
    integer start_time;
    integer end_time;
    integer elapsed_time;
    real actual_value;
    real computed_value;
    real previous_computed_value;
    real relative_error;
    reg done;  // Boolean variable to control loop exit

    // Instantiate the Unit Under Test (UUT)
    fast_inverse_sqrt uut (
        .number(number),
        .result(result)
    );

    initial begin
        // Initialize Inputs
        number = 32'h40800000; // Default to 4.0 in IEEE 754 floating point format
        accuracy_threshold = 0.005; // Accuracy threshold of 0.5%

        // Initialize previous computed value
        previous_computed_value = 0.0;

        // Measure the time until the accuracy is within the specified threshold
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
                done = 1;  // Set done to 1 to exit loop
            end
            previous_computed_value = computed_value;
            //$display("Elapsed time: %0d ns", elapsed_time);
            #1; // Wait for 1 time unit
            //$finish;
        end
        while(done) begin
            
            $display("Elapsed time: %0d ns", elapsed_time);
            $finish;
        end
        

        // Display the results
        /*$display("Input number: %f", $bitstoreal(number));
        $display("Fast Inverse Square Root result: %f", computed_value);
        $display("Actual value: %f", actual_value);
        $display("Relative error: %f", relative_error);
        $display("Elapsed time: %0d ns", elapsed_time);

        // Finish the simulation
        $finish;*/
    end
      
endmodule