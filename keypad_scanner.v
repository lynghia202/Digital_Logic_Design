module keypad_scanner (
    input wire clk,              // 50MHz clock
    input wire reset,            // Active high reset
    input wire [3:0] rows,       // Row inputs (pulled-up)
    output reg [3:0] cols,       // Column outputs (active low)
    output reg [3:0] key_value,  // Detected key code (0-15)
    output reg key_valid         // One-cycle pulse when key pressed
);

    reg [15:0] scan_timer;
    reg [1:0] scan_index;
    wire scan_tick;
    
    assign scan_tick = (scan_timer == 16'd49999);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            scan_timer <= 16'd0;
            scan_index <= 2'd0;
        end else if (scan_tick) begin
            scan_timer <= 16'd0;
            scan_index <= scan_index + 2'd1;
        end else begin
            scan_timer <= scan_timer + 16'd1;
        end
    end

    // Column output generation
    always @(*) begin
        case (scan_index)
            2'b00: cols = 4'b1110; 
            2'b01: cols = 4'b1101; 
            2'b10: cols = 4'b1011; 
            2'b11: cols = 4'b0111; 
            default: cols = 4'b1111;
        endcase
    end

    // ===== Two-stage synchronizer =====
    reg [3:0] row_sync1, row_sync2;
    
    always @(posedge clk) begin
        row_sync1 <= rows;
        row_sync2 <= row_sync1;
    end

    // ===== Debouncing (100us) =====
    reg [19:0] debounce_counter;
    reg [3:0] row_stable;
    reg [3:0] rows_debounced;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_counter <= 20'd0;
            row_stable <= 4'b1111;
            rows_debounced <= 4'b1111;
        end else begin
            if (row_sync2 != row_stable) begin
                debounce_counter <= 20'd0;
                row_stable <= row_sync2;
            end else begin
                if (debounce_counter < 20'd4999) begin  
                    debounce_counter <= debounce_counter + 20'd1;
                end else begin
                    rows_debounced <= row_stable;
                end
            end
        end
    end
    
    // ===== Key Detection =====
    wire [3:0] key_code;
    reg [3:0] key_code_reg;
    
    always @(*) begin
        key_code_reg = 4'hF;

        case (scan_index)
            2'b00: begin
                if (rows_debounced == 4'b1110)      key_code_reg = 4'h1;
                else if (rows_debounced == 4'b1101) key_code_reg = 4'h4;
                else if (rows_debounced == 4'b1011) key_code_reg = 4'h7;
                else if (rows_debounced == 4'b0111) key_code_reg = 4'hE;
            end
            
            2'b01: begin
                if (rows_debounced == 4'b1110)      key_code_reg = 4'h2;
                else if (rows_debounced == 4'b1101) key_code_reg = 4'h5;
                else if (rows_debounced == 4'b1011) key_code_reg = 4'h8;
                else if (rows_debounced == 4'b0111) key_code_reg = 4'h0;
            end

            2'b10: begin
                if (rows_debounced == 4'b1110)      key_code_reg = 4'h3;
                else if (rows_debounced == 4'b1101) key_code_reg = 4'h6;
                else if (rows_debounced == 4'b1011) key_code_reg = 4'h9;
                else if (rows_debounced == 4'b0111) key_code_reg = 4'hF;
            end

            2'b11: begin
                if (rows_debounced == 4'b1110)      key_code_reg = 4'hA;
                else if (rows_debounced == 4'b1101) key_code_reg = 4'hB;
                else if (rows_debounced == 4'b1011) key_code_reg = 4'hC;
                else if (rows_debounced == 4'b0111) key_code_reg = 4'hD;
            end
        endcase
    end
    
    assign key_code = key_code_reg;

    // ===== Key Press Detection with State Machine =====
    localparam IDLE = 2'b00;
    localparam KEY_DETECTED = 2'b01;
    localparam WAIT_RELEASE = 2'b10;
    
    reg [1:0] state;
    reg [3:0] detected_key;
    reg [23:0] release_timer;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            key_valid <= 1'b0;
            key_value <= 4'hF;
            detected_key <= 4'hF;
            release_timer <= 24'd0;
        end else begin
            key_valid <= 1'b0;  // Default
            
            case (state)
                IDLE: begin
                    // Chờ phát hiện phím hợp lệ
                    if (key_code != 4'hF) begin
                        detected_key <= key_code;
                        state <= KEY_DETECTED;
                        release_timer <= 24'd0;
                    end
                end
                
                KEY_DETECTED: begin
                    // Phát key_valid 1 lần duy nhất
                    key_valid <= 1'b1;
                    key_value <= detected_key;
                    state <= WAIT_RELEASE;
                end
                
                WAIT_RELEASE: begin
                    // Đợi phím được thả (key_code == F liên tục trong 50ms)
                    if (key_code == 4'hF) begin
                        if (release_timer < 24'd2500000) begin  // 50ms
                            release_timer <= release_timer + 24'd1;
                        end else begin
                            // Phím đã thả ổn định, về IDLE
                            state <= IDLE;
                            detected_key <= 4'hF;
                            release_timer <= 24'd0;
                        end
                    end else begin
                        // Vẫn còn phím được nhấn, reset counter
                        release_timer <= 24'd0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule