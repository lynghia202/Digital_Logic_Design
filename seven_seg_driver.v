module seven_seg_driver (
    input wire clk,              // 50MHz clock
    input wire reset,            // Active high reset
    input wire [15:0] digits,    // 4 hex digits [D3, D2, D1, D0]
    output reg [6:0] seg_out,    // Segment outputs {g,f,e,d,c,b,a}
    output reg [3:0] digit_sel   // Digit select (Active-LOW cho CC)
);

    // ===== Stage 1: Refresh Counter =====
    reg [17:0] refresh_counter; // SỬA: Tăng lên 18-bit
    reg [1:0] current_digit_s1; // Stage 1 register (cho bộ chọn)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            refresh_counter <= 18'd0; 
            current_digit_s1 <= 2'b0;
        end else begin
            refresh_counter <= refresh_counter + 18'd1; 
            current_digit_s1 <= refresh_counter[17:16];
        end
    end

    // ===== Stage 2: Hex MUX  =====
    reg [3:0] current_hex_s2; 
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_hex_s2 <= 4'hF;
        end else begin
            case (current_digit_s1)
                2'b00: current_hex_s2 <= digits[15:12]; // D3
                2'b01: current_hex_s2 <= digits[11:8];  // D2
                2'b10: current_hex_s2 <= digits[7:4];   // D1
                2'b11: current_hex_s2 <= digits[3:0];   // D0
            endcase
        end
    end

    // ===== Stage 3: Hex-to-Segment Decoder (Registered) =====
    reg [6:0] decoded_segments_s3; 
    
    wire [6:0] decoded_segments_comb;
    hex_to_7seg decoder_inst (
        .hex_in(current_hex_s2),
        .seg_out(decoded_segments_comb)
    );
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            decoded_segments_s3 <= 7'b0000000;
        end else begin
            decoded_segments_s3 <= decoded_segments_comb;
        end
    end

    // ===== Pipeline Delay cho Digit Select =====
    reg [1:0] current_digit_s2;
    reg [1:0] current_digit_s3;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_digit_s2 <= 2'b0;
            current_digit_s3 <= 2'b0;
        end else begin
            current_digit_s2 <= current_digit_s1; // S1 -> S2
            current_digit_s3 <= current_digit_s2; // S2 -> S3
        end
    end

    // ===== Stage 4: Output Registers (Active-LOW CC) =====
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seg_out <= 7'b0000000;
            digit_sel <= 4'b1111; // Tắt (Active-LOW)
        end else begin
            seg_out <= decoded_segments_s3;
            
            case (current_digit_s3)
                2'b00: digit_sel <= 4'b0111; // Bật đèn 3 (trái)
                2'b01: digit_sel <= 4'b1011; // Bật đèn 2
                2'b10: digit_sel <= 4'b1101; // Bật đèn 1
                2'b11: digit_sel <= 4'b1110; // Bật đèn 0 (phải)
            endcase
        end
    end

endmodule