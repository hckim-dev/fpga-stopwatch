`timescale 1ns / 1ps

module minsec_counter (
    input wire clk,
    input wire reset,
    input wire tick_1ms,
    input wire enable,
    input wire clear,
    output wire dot_on,
    output wire [13:0] display_data
);

  reg [9:0] r_ms_count;
  reg [5:0] r_second;
  reg [5:0] r_minute;

  // 일시정지 시 밀리초 보존, clear 우선 처리
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r_ms_count <= 0;
      r_second   <= 0;
      r_minute   <= 0;
    end else if (clear) begin
      r_ms_count <= 0;
      r_second   <= 0;
      r_minute   <= 0;
    end else if (enable && tick_1ms) begin
      if (r_ms_count == 999) begin
        r_ms_count <= 0;
        if (r_second == 59) begin
          r_second <= 0;
          if (r_minute == 59) begin
            r_minute <= 0;
          end else begin
            r_minute <= r_minute + 1;
          end
        end else begin
          r_second <= r_second + 1;
        end
      end else begin
        r_ms_count <= r_ms_count + 1;
      end
    end
  end

  // 분초 값의 십진수 MMSS 변환
  // 기존 밀리초 카운터를 활용한 1 Hz 점멸 위상 생성
  assign dot_on = (r_ms_count < 500);

  // 분초 값의 십진수 MMSS 변환
  assign display_data = r_minute * 100 + r_second;

endmodule
