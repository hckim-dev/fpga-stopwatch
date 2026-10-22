`timescale 1ns / 1ps

module fnd_digit_display (
    input  wire [1:0] digit_sel,
    input  wire [3:0] digit_1,
    input  wire [3:0] digit_10,
    input  wire [3:0] digit_100,
    input  wire [3:0] digit_1000,
    output reg  [7:0] seg,
    output reg  [3:0] an
);

  reg [3:0] r_bcd_data;  // 선택 자리 BCD 전달용 조합논리 변수

  // an active-low 자리 선택: 0=일, 1=십, 2=백, 3=천
  always @(*) begin
    case (digit_sel)
      2'b00: begin
        r_bcd_data = digit_1;
        an = 4'b1110;
      end
      2'b01: begin
        r_bcd_data = digit_10;
        an = 4'b1101;
      end
      2'b10: begin
        r_bcd_data = digit_100;
        an = 4'b1011;
      end
      2'b11: begin
        r_bcd_data = digit_1000;
        an = 4'b0111;
      end
      default: begin
        r_bcd_data = 4'b0000;
        an = 4'b1111;
      end
    endcase
  end

  // seg[7:0] = {소수점, g, f, e, d, c, b, a}, 0인 세그먼트가 켜짐
  // 숫자 디코더의 소수점 끄기, fnd_controller에서 점멸 제어
  always @(*) begin
    case (r_bcd_data)
      4'd0: seg = 8'b11000000;
      4'd1: seg = 8'b11111001;
      4'd2: seg = 8'b10100100;
      4'd3: seg = 8'b10110000;
      4'd4: seg = 8'b10011001;
      4'd5: seg = 8'b10010010;
      4'd6: seg = 8'b10000010;
      4'd7: seg = 8'b11111000;
      4'd8: seg = 8'b10000000;
      4'd9: seg = 8'b10010000;
      default: seg = 8'b11111111;  // 0~9 이외 입력의 전체 소등
    endcase
  end

endmodule
