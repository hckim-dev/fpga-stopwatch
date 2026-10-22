`timescale 1ns / 1ps

module stopwatch_counter (
    input wire clk,
    input wire reset,
    input wire tick_1ms,
    input wire enable,
    input wire clear,
    output wire [13:0] display_data
);

  reg [3:0] r_ms_divider;
  reg [6:0] r_centisecond;
  reg [6:0] r_second;

  // 1 ms tick 10개를 누적해 1/100초 계수
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r_ms_divider  <= 0;
      r_centisecond <= 0;
      r_second      <= 0;
    end else if (clear) begin
      r_ms_divider  <= 0;
      r_centisecond <= 0;
      r_second      <= 0;
    end else if (enable && tick_1ms) begin
      if (r_ms_divider == 9) begin
        r_ms_divider <= 0;

        if (r_centisecond == 99) begin
          r_centisecond <= 0;
          if (r_second == 99) begin
            r_second <= 0;
          end else begin
            r_second <= r_second + 1;
          end
        end else begin
          r_centisecond <= r_centisecond + 1;
        end
      end else begin
        r_ms_divider <= r_ms_divider + 1;
      end
    end
  end

  // 초와 1/100초를 SS.hh 표시 데이터로 변환
  assign display_data = r_second * 100 + r_centisecond;

endmodule
