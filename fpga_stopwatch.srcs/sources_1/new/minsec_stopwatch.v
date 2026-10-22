`timescale 1ns / 1ps

module minsec_stopwatch (
    input wire clk,
    input wire reset,
    input wire tick_1ms,
    input wire [2:0] btn_pulse,
    output wire paused,
    output wire dot_on,
    output wire [15:0] led,
    output wire [13:0] display_data
);

  localparam [1:0] ClockMode = 2'b00;
  localparam [1:0] StopwatchRun = 2'b01;
  localparam [1:0] StopwatchPause = 2'b10;

  reg [1:0] r_mode;
  wire w_clock_dot_on;
  wire [13:0] w_clock_data;
  wire [13:0] w_stopwatch_data;
  wire w_stopwatch_enable;
  wire w_stopwatch_clear;

  // 버튼 동시 입력 우선순위: 모드 변경 > 초기화 > 일시정지/재개
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r_mode <= ClockMode;
    end else if (btn_pulse[0]) begin
      if (r_mode == ClockMode) begin
        r_mode <= StopwatchRun;
      end else begin
        r_mode <= ClockMode;
      end
    end else begin
      case (r_mode)
        ClockMode: r_mode <= ClockMode;

        StopwatchRun: begin
          if (!btn_pulse[1] && btn_pulse[2]) begin
            r_mode <= StopwatchPause;
          end
        end

        StopwatchPause: begin
          if (!btn_pulse[1] && btn_pulse[2]) begin
            r_mode <= StopwatchRun;
          end
        end

        default: r_mode <= ClockMode;
      endcase
    end
  end

  // 제어 버튼 처리 클럭의 계수 차단
  assign w_stopwatch_enable = (r_mode == StopwatchRun) && !(|btn_pulse);
  assign w_stopwatch_clear  = (r_mode != ClockMode) && !btn_pulse[0] && btn_pulse[1];

  // 표시 모드와 무관한 분초 시계 연속 계수
  minsec_counter u_clock_counter (
      .clk(clk),
      .reset(reset),
      .tick_1ms(tick_1ms),
      .enable(1'b1),
      .clear(1'b0),
      .dot_on(w_clock_dot_on),
      .display_data(w_clock_data)
  );

  // 스톱워치는 10 ms 단위로 SS.hh 형식 계수
  stopwatch_counter u_stopwatch_counter (
      .clk(clk),
      .reset(reset),
      .tick_1ms(tick_1ms),
      .enable(w_stopwatch_enable),
      .clear(w_stopwatch_clear),
      .display_data(w_stopwatch_data)
  );

  // 분초 시계는 점멸, 스톱워치 시간 표시는 상시 점등
  assign dot_on = (r_mode == ClockMode) ? w_clock_dot_on : 1'b1;

  assign paused = (r_mode == StopwatchPause);
  assign display_data = (r_mode == ClockMode) ? w_clock_data : w_stopwatch_data;
  assign led = {13'b0, (r_mode == StopwatchPause), (r_mode == StopwatchRun), (r_mode == ClockMode)};

endmodule
