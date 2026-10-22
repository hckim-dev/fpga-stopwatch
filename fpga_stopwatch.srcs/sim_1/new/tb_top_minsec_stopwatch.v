`timescale 1ns / 1ps

module tb_top_minsec_stopwatch;
  reg clk = 0;
  reg reset = 1;
  reg [2:0] btn = 0;
  wire [15:0] led;
  wire [7:0] seg;
  wire [3:0] an;
  integer pulse_count = 0;
  integer saved_ms;
  integer saved_clock;
  integer i;
  integer digit;
  reg [3:0] seen_digits = 0;

  // 실제 시간 분주 검증 및 통합 시험 가속
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

  wire real_tick;
  tick_generator u_real_tick (
      .clk  (clk),
      .reset(reset),
      .tick (real_tick)
  );
  integer real_cycles = 0;
  integer last_tick = 0;
  integer real_tick_count = 0;

  always @(posedge clk) begin
    if (reset) begin
      real_cycles = 0;
      last_tick = 0;
      real_tick_count = 0;
    end else begin
      real_cycles = real_cycles + 1;
      #1;
      if (real_tick) begin
        if (real_cycles - last_tick != 100_000) $fatal(1, "1 ms tick period");
        last_tick = real_cycles;
        real_tick_count = real_tick_count + 1;
      end
    end
  end

  always #5 clk = ~clk;
  always @(posedge clk) if (!dut.w_reset && dut.w_btn_pulse[0]) pulse_count = pulse_count + 1;


  integer clock_ms = 0;
  integer dot_checks = 0;
  reg expected_dot;

  // 독립 tick 누적으로 500 ms ON / 500 ms OFF 및 모드별 Dot 검증
  always @(posedge clk) begin
    if (dut.w_reset) begin
      clock_ms = 0;
    end else if (dut.w_tick_1ms) begin
      clock_ms = (clock_ms + 1) % 1000;
    end

    #1;
    if (!dut.w_reset) begin
      expected_dot = (led == 1) ? (clock_ms < 500) : 1'b1;
      if (dut.w_dot_on !== expected_dot) begin
        $fatal(1, "Dot phase/mode mismatch at ms=%0d", clock_ms);
      end
      if (!dut.w_animation_active && seg[7] !== !(expected_dot && (an == 4'b1011))) begin
        $fatal(1, "Dot scan output mismatch");
      end
      dot_checks = dot_checks + 1;
    end
  end


  task cycles;
    input integer n;
    begin
      repeat (n) @(negedge clk);
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


  function [6:0] segments;
    input integer value;
    begin
      case (value)
        0: segments = 7'h40;
        1: segments = 7'h79;
        2: segments = 7'h24;
        3: segments = 7'h30;
        4: segments = 7'h19;
        5: segments = 7'h12;
        6: segments = 7'h02;
        7: segments = 7'h78;
        8: segments = 7'h00;
        9: segments = 7'h10;
        default: segments = 7'h7f;
      endcase
    end
  endfunction

  // 한 시간 계수, 경계 및 부분 시간 보존 시험용 카운터
  reg counter_reset = 1;
  reg counter_tick = 0;
  reg counter_enable = 1;
  reg counter_clear = 0;
  wire [13:0] counter_data;
  reg counter_done = 0;
  minsec_counter u_counter (
      .clk(clk),
      .reset(counter_reset),
      .tick_1ms(counter_tick),
      .enable(counter_enable),
      .clear(counter_clear),
      .display_data(counter_data)
  );

  initial begin
    cycles(4);
    counter_reset = 0;
    counter_tick  = 1;
    // 1 tick = 1 ms 기준 한 시간 계수 가속 검증
    for (i = 1; i <= 3_600_000; i = i + 1) begin
      @(negedge clk);
      if (i % 1000 == 0 && counter_data !== ((i / 60000) % 60) * 100 + (i / 1000) % 60)
        $fatal(1, "time mismatch at tick %0d: %0d", i, counter_data);
    end
    if (counter_data !== 0) $fatal(1, "hour rollover");
    cycles(250);
    counter_enable = 0;
    cycles(100);
    if (u_counter.r_ms_count !== 250) $fatal(1, "pause fractional time");
    counter_enable = 1;
    cycles(750);
    if (counter_data !== 1 || u_counter.r_ms_count !== 0) $fatal(1, "resume fractional time");
    cycles(999);
    counter_clear = 1;
    cycles(1);
    if (counter_data !== 0 || u_counter.r_ms_count !== 0) $fatal(1, "clear priority");
    counter_clear  = 0;
    counter_enable = 0;
    counter_done   = 1;
  end

  initial begin
    cycles(4);
    reset = 0;
    cycles(8);
    if (led !== 1) $fatal(1, "reset mode");
    // 4클럭 미만 잡음 제거 검증, 하강 에지에서 입력 변경
    btn = 1;
    cycles(2);
    btn = 0;
    cycles(12);
    if (led !== 1 || pulse_count != 0) $fatal(1, "button bounce");
    btn = 1;
    cycles(100);
    if (led !== 2 || pulse_count != 1) $fatal(1, "held button retrigger");
    btn = 0;
    cycles(16);
    cycles(1300);
    press(4);
    if (led !== 4) $fatal(1, "pause mode");
    saved_ms = dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_count;
    saved_clock = dut.u_minsec_stopwatch.w_clock_data;
    cycles(4200);
    if (dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_count !== saved_ms)
      $fatal(1, "paused stopwatch changed");
    if (dut.u_minsec_stopwatch.w_clock_data == saved_clock) $fatal(1, "background clock stopped");
    press(2);
    if (led !== 4 || dut.w_display_data !== 0) $fatal(1, "clear must preserve pause");
    press(4);
    cycles(4050);
    press(4);
    if (led !== 4 || dut.w_display_data !== 1) $fatal(1, "stopwatch second");
    press(1);
    if (led !== 1) $fatal(1, "return clock");
    saved_ms = dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_count;
    cycles(100);
    if (dut.u_minsec_stopwatch.u_stopwatch_counter.r_ms_count !== saved_ms)
      $fatal(1, "clock mode stopwatch changed");
    press(1);
    if (led !== 2) $fatal(1, "reenter stopwatch run");
    press(6);
    if (led !== 2 || dut.w_display_data !== 0) $fatal(1, "center priority");
    press(7);
    if (led !== 1) $fatal(1, "left priority");
    // 각 자리의 anode, 숫자 및 분초 구분 Dot 검증
    repeat (40) begin
      @(negedge clk);
      case (an)
        4'b1110: begin
          digit = dut.w_display_data % 10;
          seen_digits[0] = 1;
        end
        4'b1101: begin
          digit = (dut.w_display_data / 10) % 10;
          seen_digits[1] = 1;
        end
        4'b1011: begin
          digit = (dut.w_display_data / 100) % 10;
          seen_digits[2] = 1;
        end
        4'b0111: begin
          digit = (dut.w_display_data / 1000) % 10;
          seen_digits[3] = 1;
        end
        default: $fatal(1, "anode selection");
      endcase
      if (seg[6:0] !== segments(digit)) $fatal(1, "segment value");
      if (seg[7] !== !(dut.w_dot_on && (an == 4'b1011))) $fatal(1, "decimal point");
    end
    if (seen_digits !== 15) $fatal(1, "missing digit");
    #2;
    reset = 1;
    #1;
    if (led !== 1 || dut.w_display_data !== 0) $fatal(1, "asynchronous reset");
    cycles(4);
    reset = 0;
    wait (counter_done);
    if (real_tick_count < 2) $fatal(1, "real tick not tested");
    $display(
        "PASS: 1Hz Dot phase/modes, hour rollover, pause/resume, clear, buttons, priority, FND, real 1ms tick");
    $finish;
  end

  initial begin
    #40_000_000;
    $fatal(1, "watchdog timeout");
  end

endmodule
