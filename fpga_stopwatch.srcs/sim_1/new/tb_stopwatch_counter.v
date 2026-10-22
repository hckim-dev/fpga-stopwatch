`timescale 1ns / 1ps

module tb_stopwatch_counter;
  reg clk = 0;
  reg reset = 1;
  reg tick_1ms = 0;
  reg enable = 1;
  reg clear = 0;
  reg [2:0] scenario = 0;
  wire [13:0] display_time;

  stopwatch_counter dut (
      .clk(clk),
      .reset(reset),
      .tick_1ms(tick_1ms),
      .enable(enable),
      .clear(clear),
      .display_data(display_time)
  );

  always #5 clk = ~clk;

  // 단위 테스트에서 매 클럭을 1 ms tick으로 사용
  task wait_ticks;
    input integer count;
    begin
      repeat (count) @(negedge clk);
    end
  endtask

  initial begin
    wait_ticks(2);
    reset = 0;
    tick_1ms = 1;

    // 1. 10 ms 해상도 및 00.99 → 01.00 올림
    scenario = 1;
    wait_ticks(9);
    if (display_time !== 0) $fatal(1, "before 10 ms");
    wait_ticks(1);
    if (display_time !== 1) $fatal(1, "10 ms resolution");
    wait_ticks(980);
    if (display_time !== 99) $fatal(1, "00.99");
    wait_ticks(10);
    if (display_time !== 100) $fatal(1, "01.00 carry");

    // 2. 일시정지 시 10 ms 미만의 부분 시간까지 보존
    scenario = 2;
    wait_ticks(2);
    enable = 0;
    wait_ticks(20);
    if (display_time !== 100) $fatal(1, "pause");
    enable = 1;
    wait_ticks(7);
    if (display_time !== 100) $fatal(1, "resume too early");
    wait_ticks(1);
    if (display_time !== 101) $fatal(1, "resume fraction");

    // 3. 초기화 및 최대 표시 시간 순환
    scenario = 3;
    clear = 1;
    wait_ticks(1);
    clear = 0;
    if (display_time !== 0) $fatal(1, "clear");
    wait_ticks(99990);
    if (display_time !== 9999) $fatal(1, "99.99");
    wait_ticks(10);
    if (display_time !== 0) $fatal(1, "100 second rollover");

    $display("PASS: 10ms resolution, second carry, pause/resume, clear, rollover");
    $finish;
  end

  initial begin
    #2_000_000;
    $fatal(1, "watchdog timeout");
  end
endmodule
