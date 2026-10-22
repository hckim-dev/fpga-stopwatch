`timescale 1ns / 1ps

module top_minsec_stopwatch #(
    parameter integer TickCount       = 100_000,    // 100 MHz에서 1 ms
    parameter integer DebounceCount   = 1_000_000,  // 10 ms 연속 안정 확인
    parameter integer IdleTimeMs      = 5_000,      // 일시정지 후 무입력 대기 시간
    parameter integer AnimationStepMs = 100         // 회전 선분 이동 간격
) (
    input wire clk,
    input wire reset,
    input wire [2:0] btn,  // [0]: 왼쪽, [1]: 가운데, [2]: 오른쪽
    output wire [15:0] led,
    output wire [7:0] seg,
    output wire [3:0] an
);

  wire w_dot_on;
  wire w_paused;
  wire w_animation_active;
  wire [7:0] w_animation_seg;
  wire [7:0] w_time_seg;
  wire w_reset;
  wire w_tick_1ms;
  wire [2:0] w_clean_btn;
  wire [2:0] w_btn_pulse;
  wire [13:0] w_display_data;
  reg [2:0] r_prev_btn;

  reset_synchronizer u_reset_synchronizer (
      .clk(clk),
      .reset(reset),
      .synced_reset(w_reset)
  );

  tick_generator #(
      .TickCount(TickCount)
  ) u_tick_generator (
      .clk  (clk),
      .reset(w_reset),
      .tick (w_tick_1ms)
  );

  btn_debouncer #(
      .DebounceCount(DebounceCount)
  ) u_btn_debouncer_0 (
      .clk(clk),
      .reset(w_reset),
      .noisy_btn(btn[0]),
      .clean_btn(w_clean_btn[0])
  );

  btn_debouncer #(
      .DebounceCount(DebounceCount)
  ) u_btn_debouncer_1 (
      .clk(clk),
      .reset(w_reset),
      .noisy_btn(btn[1]),
      .clean_btn(w_clean_btn[1])
  );

  btn_debouncer #(
      .DebounceCount(DebounceCount)
  ) u_btn_debouncer_2 (
      .clk(clk),
      .reset(w_reset),
      .noisy_btn(btn[2]),
      .clean_btn(w_clean_btn[2])
  );

  // 버튼당 1회 동작을 위한 상승 에지 검출
  always @(posedge clk or posedge w_reset) begin
    if (w_reset) begin
      r_prev_btn <= 0;
    end else begin
      r_prev_btn <= w_clean_btn;
    end
  end

  assign w_btn_pulse = w_clean_btn & ~r_prev_btn;

  minsec_stopwatch u_minsec_stopwatch (
      .clk(clk),
      .reset(w_reset),
      .tick_1ms(w_tick_1ms),
      .btn_pulse(w_btn_pulse),
      .paused(w_paused),
      .dot_on(w_dot_on),
      .led(led),
      .display_data(w_display_data)
  );

  fnd_controller u_fnd_controller (
      .clk(clk),
      .reset(w_reset),
      .tick(w_tick_1ms),
      .display_data(w_display_data),
      .dot_on(w_dot_on),
      .seg(w_time_seg),
      .an(an)
  );

  fnd_idle_animation #(
      .IdleTimeMs(IdleTimeMs),
      .AnimationStepMs(AnimationStepMs)
  ) u_fnd_idle_animation (
      .clk(clk),
      .reset(w_reset),
      .tick_1ms(w_tick_1ms),
      .paused(w_paused),
      .button_active(|w_clean_btn),
      .active(w_animation_active),
      .seg(w_animation_seg)
  );

  // 자리 선택 유지 및 시간/애니메이션 선분 선택
  assign seg = w_animation_active ? w_animation_seg : w_time_seg;

endmodule
