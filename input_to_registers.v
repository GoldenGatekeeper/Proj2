//Listens for 01011010 and control bit. Puts it all in a shift register, then seperates input A, Input B into 2 16 bit registers
module sequence_detector(
    input clk,           // Clock input
    input reset,         // Reset input
    input din,           // Serial input
    output reg detected, // Output indicating sequence detection
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
                input_a <= input_a_reg; // Update input_a shift register
                input_b <= input_b_reg; // Update input_b shift register
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule
