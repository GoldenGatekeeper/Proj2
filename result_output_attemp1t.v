module bcd_arithmetic(
    input clk,           // Clock input
    input reset,         // Reset input
    input control,       // Control input for selecting addition or subtraction
    input [15:0] input_a,// Input A (BCD)
    input [15:0] input_b,// Input B (BCD)
    output reg result_serial, // Serial output result
    output reg [15:0] result // Output result (BCD)
);

// Define states for FSM
parameter IDLE = 2'b00;
parameter SHIFTING_RESULT = 2'b01;
parameter SERIAL_OUTPUT = 2'b10;

reg [3:0] a[3:0], b[3:0], sum[3:0], carry[3:0];
reg [15:0] serial_out;
reg [1:0] state;      // FSM state register

always @* begin
    for (int i = 0; i < 4; i = i + 1) begin
        if (control == 1'b0) // Addition
            sum[i] = a[i] + b[i] + carry[i];
        else // Subtraction
            sum[i] = a[i] - b[i] - carry[i];

        if (sum[i] >= 10 || sum[i] < 0) begin
            sum[i] = sum[i] - 10;
            carry[i+1] = 1;
        end else
            carry[i+1] = 0;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        result <= 16'b0; // Reset result
        serial_out <= 16'b0; // Reset serial_out
        state <= IDLE;       // Reset state
        result_serial <= 1'b0; // Reset result_serial
    end else begin
        case (state)
            IDLE: begin
                if (control == 1'b0) begin // Addition
                    for (int i = 0; i < 4; i = i + 1)
                        result[4*i +: 4] <= sum[i];
                end else begin // Subtraction
                    for (int i = 0; i < 4; i = i + 1)
                        result[4*i +: 4] <= sum[i];
                end
                state <= SHIFTING_RESULT; // Move to shifting result state
            end
            SHIFTING_RESULT: begin
                if (serial_out == 16'b10010110) begin // Detect "10010110"
                    state <= SERIAL_OUTPUT; // Move to serial output state
                end
                else
                    serial_out <= {serial_out[14:0], 1'b0}; // Shift in 0
            end
            SERIAL_OUTPUT: begin
                if (result_serial) begin
                    serial_out <= {serial_out[14:0], result[15]}; // Shift result
                end
                if (!result_serial && serial_out == 16'b0) begin
                    state <= IDLE; // Return to IDLE state after complete
                end
            end
            default: state <= IDLE;
        endcase
    end
end

// Separate always block for result_serial
always @(posedge clk) begin
    if (!reset) begin
        if (state == SERIAL_OUTPUT) begin
            result_serial <= 1'b1; // Enable serial output
        end
        else begin
            result_serial <= 1'b0; // Disable serial output
        end
    end
end

// Split input_a and input_b into individual BCD digits
assign a[0] = input_a[3:0];
assign a[1] = input_a[7:4];
assign a[2] = input_a[11:8];
assign a[3] = input_a[15:12];

assign b[0] = input_b[3:0];
assign b[1] = input_b[7:4];
assign b[2] = input_b[11:8];
assign b[3] = input_b[15:12];

endmodule
