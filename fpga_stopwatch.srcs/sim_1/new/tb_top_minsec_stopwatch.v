`timescale 1ns / 1ps

module tb_top_minsec_stopwatch;
  reg clk = 0;
  reg reset = 1;
  reg [2:0] btn = 0;
  reg [3:0] scenario = 0;
  wire [15:0] led;
  wire [7:0] seg;
  wire [3:0] an;

  // 계수 비율 유지, 시뮬레이션에서만 1 ms를 100 ns로 단축
  top_minsec_stopwatch #(
      .TickCount(10),
      .DebounceCount(4)
  ) dut (
      .clk(clk),
      .reset(reset),
      .btn(btn),
      .led(led),
      .seg(seg),
      .an(an)
  );

  // 타이밍 차트에서 확인할 핵심 신호
  wire tick_1ms = dut.w_tick_1ms;
  wire [2:0] btn_pulse = dut.w_btn_pulse;
  wire [1:0] mode = dut.u_minsec_stopwatch.r_mode;
  wire [13:0] display_time = dut.w_display_data;
  wire [13:0] clock_time = dut.u_minsec_stopwatch.w_clock_data;
  wire [13:0] stopwatch_time = dut.u_minsec_stopwatch.w_stopwatch_data;
  wire animation_active = dut.w_animation_active;
  wire dot_on = dut.w_dot_on;
  reg [13:0] saved_time;
  reg [13:0] saved_clock;
  reg [3:0] saved_fraction;

  always #5 clk = ~clk;

  task wait_ms;
    input integer duration_ms;
    begin
      repeat (duration_ms) @(negedge tick_1ms);
      @(negedge clk);
    end
  endtask

  task press_button;
    input [2:0] mask;
    begin
      @(negedge clk);
      btn = mask;
      wait_ms(2);
      btn = 0;
      wait_ms(2);
    end
  endtask

  initial begin
    repeat (5) @(negedge clk);
    reset = 0;

    // 1. 분초 시계 계수 및 스톱워치 전용 버튼 무시
    scenario = 1;
    wait_ms(499);
    if (dot_on !== 1) $fatal(1, "clock dot on");
    wait_ms(2);
    if (dot_on !== 0) $fatal(1, "clock dot off");
    wait_ms(499);
    if (mode !== 0 || clock_time !== 1) $fatal(1, "clock mode");
    if (dot_on !== 1) $fatal(1, "clock dot period");
    press_button(3'b110);
    if (mode !== 0 || stopwatch_time !== 0) $fatal(1, "clock button handling");
    saved_clock = clock_time;

    // 2. 모드 전환 후 10 ms 해상도 스톱워치 실행
    scenario = 2;
    press_button(3'b001);
    wait_ms(1230);
    press_button(3'b100);
    if (mode !== 2 || stopwatch_time < 123 || stopwatch_time > 124)
      $fatal(1, "stopwatch run to pause");

    // 3. 일시정지 중 값 보존 및 가운데 버튼 우선 초기화
    scenario   = 3;
    saved_time = stopwatch_time;
    wait_ms(250);
    if (stopwatch_time !== saved_time) $fatal(1, "paused time changed");
    press_button(3'b110);
    if (mode !== 2 || stopwatch_time !== 0) $fatal(1, "clear must preserve pause");

    // 4. 5초 무입력 애니메이션, 버튼 누름 유지 및 재개
    scenario = 4;
    wait_ms(4990);
    if (animation_active !== 0) $fatal(1, "animation started early");
    wait_ms(20);
    if (animation_active !== 1) $fatal(1, "animation timeout");
    btn = 3'b010;
    wait_ms(5100);
    if (animation_active !== 0 || mode !== 2)
      $fatal(1, "held center button must inhibit animation");
    btn = 0;
    wait_ms(5010);
    if (animation_active !== 1 || seg !== 8'hFE) $fatal(1, "animation after release");
    wait_ms(100);
    if (seg !== 8'hFD) $fatal(1, "animation rotation");
    press_button(3'b100);
    if (animation_active !== 0 || mode !== 1) $fatal(1, "wake and resume");

    // 5. 분초 시계는 계속 계수, 시계 화면의 스톱워치는 정지
    scenario = 5;
    wait_ms(100);
    press_button(3'b001);
    saved_time = stopwatch_time;
    saved_fraction = dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_divider;
    wait_ms(250);
    if (mode !== 0 || stopwatch_time !== saved_time ||
        dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_divider !== saved_fraction)
      $fatal(1, "stopwatch must hold in clock mode");
    if (clock_time <= saved_clock) $fatal(1, "background clock stopped");

    // 6. 시계에서 복귀 시 실행, 동시 입력 우선순위 확인
    scenario = 6;
    press_button(3'b001);
    if (mode !== 1 || stopwatch_time < saved_time) $fatal(1, "reenter stopwatch");
    press_button(3'b110);
    if (mode !== 1 || stopwatch_time !== 0) $fatal(1, "center over right");
    press_button(3'b100);
    press_button(3'b111);
    if (mode !== 0) $fatal(1, "left button priority");

    // 7. 전역 리셋으로 모드 및 두 카운터 초기화
    scenario = 7;
    reset = 1;
    #1;
    if (mode !== 0 || clock_time !== 0 || stopwatch_time !== 0 || animation_active !== 0)
      $fatal(1, "global reset");
    $display("PASS: modes, run/pause, clear, idle animation, held button, priority, reset");
    $finish;
  end

  initial begin
    #3_000_000;
    $fatal(1, "watchdog timeout");
  end
endmodule
