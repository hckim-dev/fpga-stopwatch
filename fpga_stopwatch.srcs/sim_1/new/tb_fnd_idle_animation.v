`timescale 1ns / 1ps

module tb_fnd_idle_animation;
  reg clk = 0;
  reg reset = 1;
  reg tick = 0;
  reg paused = 0;
  reg button_active = 0;
  wire active;
  wire [7:0] animation_seg;
  reg [2:0] btn = 0;
  wire [15:0] led;
  wire [7:0] seg;
  wire [3:0] an;
  integer i;
  integer saved_ms;
  reg unit_done = 0;
  reg integration_done = 0;

  always #5 clk = ~clk;

  fnd_idle_animation u_animation (
      .clk(clk),
      .reset(reset),
      .tick_1ms(tick),
      .paused(paused),
      .button_active(button_active),
      .active(active),
      .seg(animation_seg)
  );

  top_minsec_stopwatch #(
      .TickCount(4),
      .DebounceCount(4)
  ) dut (
      .clk(clk),
      .reset(reset),
      .btn(btn),
      .led(led),
      .seg(seg),
      .an(an)
  );

  task cycles;
    input integer count;
    begin
      repeat (count) @(negedge clk);
    end
  endtask

  task press;
    input [2:0] mask;
    begin
      @(negedge clk);
      btn = mask;
      cycles(16);
      btn = 0;
      cycles(16);
    end
  endtask

  function [7:0] pattern;
    input integer step;
    begin
      case (step)
        0: pattern = 8'hFE;
        1: pattern = 8'hFD;
        2: pattern = 8'hFB;
        3: pattern = 8'hF7;
        4: pattern = 8'hEF;
        5: pattern = 8'hDF;
      endcase
    end
  endfunction

  initial begin
    cycles(4);
    reset = 0;
  end

  initial begin
    cycles(6);
    tick   = 1;
    paused = 1;
    cycles(4999);
    if (active !== 0) $fatal(1, "animation started before 5000 ticks");
    cycles(1);
    if (active !== 1 || animation_seg !== 8'hFE) $fatal(1, "5000 tick boundary");
    for (i = 1; i <= 12; i = i + 1) begin
      cycles(99);
      if (animation_seg !== pattern((i - 1) % 6)) $fatal(1, "step too early");
      cycles(1);
      if (animation_seg !== pattern(i % 6)) $fatal(1, "rotation sequence");
    end
    button_active = 1;
    cycles(6000);
    if (active !== 0 || u_animation.r_idle_count !== 0) $fatal(1, "held button idle timer");
    button_active = 0;
    cycles(4999);
    button_active = 1;
    cycles(1);
    if (active !== 0) $fatal(1, "button at timeout priority");
    button_active = 0;
    cycles(5000);
    if (active !== 1) $fatal(1, "restart idle timer");
    paused = 0;
    cycles(6000);
    if (active !== 0 || u_animation.r_idle_count !== 0) $fatal(1, "not paused");
    unit_done = 1;
  end

  initial begin
    cycles(21000);
    if (dut.w_animation_active !== 0) $fatal(1, "clock mode animation");
    press(1);
    cycles(21000);
    if (dut.w_animation_active !== 0) $fatal(1, "run mode animation");
    press(4);
    saved_ms = dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_divider;
    cycles(21000);
    if (dut.w_animation_active !== 1 || seg !== dut.w_animation_seg)
      $fatal(1, "pause animation display");
    if (dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_divider !== saved_ms)
      $fatal(1, "animation changed time");
    // 가운데 버튼의 애니메이션 종료 및 초기화 동시 수행 검증
    press(2);
    if (dut.w_animation_active !== 0 || led !== 4 || dut.w_display_data !== 0)
      $fatal(1, "center wake and clear");
    cycles(21000);
    if (dut.w_animation_active !== 1) $fatal(1, "idle after clear");
    press(4);
    if (dut.w_animation_active !== 0 || led !== 2) $fatal(1, "right wake and resume");
    press(4);
    cycles(21000);
    if (dut.w_animation_active !== 1) $fatal(1, "idle after pause");
    press(1);
    if (dut.w_animation_active !== 0 || led !== 1) $fatal(1, "left wake and mode");
    press(1);
    press(4);
    btn = 2;
    cycles(21000);
    if (dut.w_animation_active !== 0) $fatal(1, "held physical button");
    btn = 0;
    cycles(21000);
    if (dut.w_animation_active !== 1) $fatal(1, "idle after release");
    reset = 1;
    cycles(2);
    if (dut.w_animation_active !== 0 || led !== 1) $fatal(1, "reset animation");
    integration_done = 1;
  end

  initial begin
    wait (unit_done && integration_done);
    $display(
        "PASS: 5s boundary, 100ms circle, held button, timeout priority, all 3 wake actions, reset");
    $finish;
  end

  initial begin
    #5_000_000;
    $fatal(1, "watchdog timeout");
  end

endmodule
