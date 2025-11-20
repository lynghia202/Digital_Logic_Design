
module hex_to_7seg (
    input [3:0] hex_in,
    output reg [6:0] seg_out  // {g,f,e,d,c,b,a}
);

    // Common Cathode encoding (1 = segment ON, 0 = segment OFF)
    always @(*) begin
        case (hex_in)
            // Numeric digits 0-9
            4'h0: seg_out = 7'b0111111;  // 0: a,b,c,d,e,f
            4'h1: seg_out = 7'b0000110;  // 1: b,c
            4'h2: seg_out = 7'b1011011;  // 2: a,b,g,e,d
            4'h3: seg_out = 7'b1001111;  // 3: a,b,g,c,d
            4'h4: seg_out = 7'b1100110;  // 4: f,g,b,c
            4'h5: seg_out = 7'b1101101;  // 5: a,f,g,c,d
            4'h6: seg_out = 7'b1111101;  // 6: a,f,g,e,d,c
            4'h7: seg_out = 7'b0000111;  // 7: a,b,c
            4'h8: seg_out = 7'b1111111;  // 8: all segments
            4'h9: seg_out = 7'b1101111;  // 9: a,b,c,d,f,g
            
            // Special characters for PASS/FAIL display
            4'hA: seg_out = 7'b1110111;  // A: a,b,c,e,f,g
            4'hB: seg_out = 7'b1110011;  // P: a,b,e,f,g
            4'hC: seg_out = 7'b1101101;  // S: a,f,g,c,d (same as 5)
            4'hD: seg_out = 7'b1110001;  // F: a,e,f,g
            4'hE: seg_out = 7'b0111000;  // L: d,e,f
            4'hF: seg_out = 7'b1000000;  // - (dash): g only
            
            default: seg_out = 7'b0000000;  // All segments OFF
        endcase
    end

endmodule