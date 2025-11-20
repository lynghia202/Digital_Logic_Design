
module password_fsm (
    input wire clk,
    input wire reset,
    input wire [3:0] key_value,
    input wire key_valid,
    output reg [15:0] display_data
);

    // ===== Key Definitions =====
    localparam KEY_C = 4'hC;  // Clear key
    localparam KEY_E = 4'hE;  // Enter key
    
    // ===== Display Character Codes =====
    localparam CHAR_A    = 4'hA;
    localparam CHAR_P    = 4'hB;
    localparam CHAR_S    = 4'hC;
    localparam CHAR_F    = 4'hD;
    localparam CHAR_L    = 4'hE;
	 localparam CHAR_I    = 4'h1;
    localparam CHAR_DASH = 4'hF;

    localparam DISP_FAIL = {CHAR_F, CHAR_A, CHAR_I, CHAR_L};  // "FAIL"
    localparam DISP_PASS = {CHAR_P, CHAR_A, CHAR_S, CHAR_S};  // "PASS"
    localparam DISP_IDLE = {CHAR_DASH, CHAR_DASH, CHAR_DASH, CHAR_DASH}; // "----"

    // ===== Password Configuration =====
    localparam [15:0] PASSWORD = 16'h1234;  // Default password: 1234

    // ===== State Machine =====
    localparam S_IDLE     = 2'b00;
    localparam S_ENTERING = 2'b01;
    localparam S_SUCCESS  = 2'b10;
    localparam S_FAIL     = 2'b11;

    reg [1:0] state, next_state;

    // ===== Data Registers =====
    reg [15:0] entered_digits;
    reg [1:0] digit_count;

    // ===== Timer for PASS/FAIL Display (2 seconds) =====
    // 50MHz * 2s = 100,000,000 cycles
    reg [26:0] timer;
    wire timer_done;
    assign timer_done = (timer == 27'd99999999);

    // ===== State Transition Logic (Combinational) =====
    always @(*) begin
        next_state = state;
        
        case (state)
            S_IDLE: begin
                if (key_valid && (key_value <= 4'd9))
                    next_state = S_ENTERING;
            end
            
            S_ENTERING: begin
                if (key_valid) begin
                    if (key_value == KEY_C)
                        next_state = S_IDLE;
                    else if (key_value == KEY_E)
                        next_state = (entered_digits == PASSWORD) ? S_SUCCESS : S_FAIL;
                    else if (key_value <= 4'd9 && digit_count == 2'd3)
                        next_state = (({entered_digits[11:0], key_value}) == PASSWORD) ? S_SUCCESS : S_FAIL;
                end
            end

            S_SUCCESS: begin
                if (timer_done)
                    next_state = S_IDLE;
            end
            
            S_FAIL: begin
                if (timer_done)
                    next_state = S_IDLE;
            end
        endcase
    end

    // ===== State Update and Data Processing (Sequential) =====
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            entered_digits <= 16'd0;
            digit_count <= 2'd0;
            display_data <= DISP_IDLE;
            timer <= 27'd0;
        end else begin
            state <= next_state;
            
            // Timer management
            if (next_state != state)
                timer <= 27'd0;
            else if (!timer_done)
                timer <= timer + 27'd1;
            
            // State-dependent data updates
            case (next_state)
                S_IDLE: begin
                    display_data <= DISP_IDLE;
                    entered_digits <= 16'd0;
                    digit_count <= 2'd0;
                end
                
                S_ENTERING: begin
                    if (state == S_IDLE && key_valid && (key_value <= 4'd9)) begin
                        // First digit entered
                        entered_digits <= {12'hFFF, key_value};
                        display_data <= {12'hFFF, key_value};
                        digit_count <= 2'd1;
                    end else if (state == S_ENTERING && key_valid && (key_value <= 4'd9) && (digit_count < 3)) begin
                        // Subsequent digits
                        entered_digits <= {entered_digits[11:0], key_value};
                        display_data <= {entered_digits[11:0], key_value};
                        digit_count <= digit_count + 2'd1;
                    end
                end

                S_SUCCESS: begin
                    display_data <= DISP_PASS;
                    entered_digits <= 16'd0;
                    digit_count <= 2'd0;
                end
                
                S_FAIL: begin
                    display_data <= DISP_FAIL;
                    entered_digits <= 16'd0;
                    digit_count <= 2'd0;
                end
            endcase
        end
    end

endmodule