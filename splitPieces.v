module bcd_arithmetic(
    input clk,           // Clock input
    input reset,         // Reset input
    input control,       // Control input for selecting addition or subtraction
    input [15:0] input_a,// Input A (BCD)
    input [15:0] input_b,// Input B (BCD)
    output reg [15:0] result // Output result (BCD)
);

reg [3:0] a[3:0], b[3:0], sum[3:0], carry[3:0];

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
    end else begin
        if (control == 1'b0) begin // Addition
            for (int i = 0; i < 4; i = i + 1)
                result[4*i +: 4] <= sum[i];
        end else begin // Subtraction
            for (int i = 0; i < 4; i = i + 1)
                result[4*i +: 4] <= sum[i];
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


module sequence_detector(
    input clk,          // Clock input
    input reset,        // Reset input
    input din,          // Serial input
    output reg detected,// Output indicating sequence detection
    output reg [15:0] input_a, // Shift register for input_a
    output reg [15:0] input_b  // Shift register for input_b
);

// Define states for FSM
parameter IDLE = 3'b000;
parameter DETECTING_PATTERN = 3'b001;
parameter DETECTING_CONTROL = 3'b010;
parameter SHIFTING = 3'b011;

reg [7:0] pattern = 8'b01011010; // Sequence to detect
reg [7:0] control_pattern = 8'b1; // Control bit pattern
reg [40:0] shift_reg; // 41-bit shift register to accommodate serial input
reg [2:0] state;      // FSM state register
reg [15:0] input_a_reg, input_b_reg; // Temporary registers for shifting input_a and input_b

// BCD Arithmetic module instantiation
bcd_arithmetic bcd_arith(
    .clk(clk),
    .reset(reset),
    .control(shift_reg[32]), // Control bit is the 33rd bit in the shift register
    .input_a(input_a_reg),
    .input_b(input_b_reg),
    .result(detected ? input_a : input_b) // Output result to detected signal when pattern detected
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        shift_reg <= 41'b0; // Reset shift register
        state <= IDLE;       // Reset state
        detected <= 1'b0;    // Reset detected signal
        input_a <= 16'b0;    // Reset input_a shift register
        input_b <= 16'b0;    // Reset input_b shift register
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= {shift_reg[39:0], din}; // Shift in serial input
                if (shift_reg[40:33] == pattern) begin
                    state <= DETECTING_CONTROL; // Move to detecting control state if pattern detected
                    detected <= 1'b1;            // Set detected signal
                end
            end
            DETECTING_CONTROL: begin
                shift_reg <= {shift_reg[39:0], din}; // Shift in serial input
                if (shift_reg[32:25] == control_pattern) begin
                    state <= SHIFTING; // Move to shifting state if control pattern detected
                end
            end
            SHIFTING: begin
                shift_reg <= {shift_reg[39:0], din}; // Shift in serial input
                input_a_reg <= {input_a_reg[14:0], shift_reg[24:17]}; // Shift input_a
                input_b_reg <= {input_b_reg[14:0], shift_reg[16:9]};   // Shift input_b
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule
