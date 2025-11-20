module keypad_password_system (
    // Clock and Reset
    input wire clk,           // 50MHz external clock
    input wire reset_n,       // Active-low reset button
    
    // 4x4 Keypad Interface
    input wire [3:0] keypad_rows,    // Row inputs (pulled-up)
    output wire [3:0] keypad_cols,   // Column outputs (active low)
    
    // 7-Segment Display (5641AS Common Cathode)
    output wire [6:0] seg_out,       // Segments {g,f,e,d,c,b,a}
    output wire [3:0] digit_sel      // Digit select (Active-LOW cho CC)
);

    // Internal reset (active high for internal logic)
    wire reset;
    assign reset = ~reset_n;

    // Interconnect wires
    wire [3:0] w_key_value;
    wire w_key_valid;
    wire [15:0] w_display_data; // Tín hiệu từ FSM -> LED

    // ===== Keypad Scanner =====
    // (Đọc phím từ keypad_rows và xuất ra w_key_value)
    keypad_scanner u_keypad (
        .clk(clk),
        .reset(reset),
        .rows(keypad_rows),
        .cols(keypad_cols),
        .key_value(w_key_value),
        .key_valid(w_key_valid)
    );

    // ===== Password FSM =====
    // (Nhận w_key_value và xuất ra w_display_data)
    password_fsm u_fsm (
        .clk(clk),
        .reset(reset),
        .key_value(w_key_value),
        .key_valid(w_key_valid),
        .display_data(w_display_data)
    );
    
    // ===== Seven Segment Display Driver =====
    seven_seg_driver u_display (
        .clk(clk),
        .reset(reset),
        .digits(w_display_data),  
        .seg_out(seg_out),
        .digit_sel(digit_sel)
    );

endmodule