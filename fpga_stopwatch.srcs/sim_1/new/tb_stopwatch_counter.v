`timescale 1ns / 1ps

module tb_stopwatch_counter;
  reg clk = 0;
  reg reset = 1;
  reg tick_1ms = 0;
  reg enable = 1;
  reg clear = 0;
  wire [13:0] display_data;
  integer i;

  stopwatch_counter dut (
      .clk(clk),
      .reset(reset),
      .tick_1ms(tick_1ms),
      .enable(enable),
      .clear(clear),
      .display_data(display_data)
  );

  always #5 clk = ~clk;

  task pulse_1ms;
    begin
      @(negedge clk);
      tick_1ms = 1;
      @(negedge clk);
      tick_1ms = 0;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    reset = 0;

    // Check 10 ms resolution and the 00.99 to 01.00 boundary.
    repeat (9) pulse_1ms;
    if (display_data !== 0) $fatal(1, "incremented before 10 ms");
    pulse_1ms;
    if (display_data !== 1) $fatal(1, "00.01 boundary");

    repeat (980) pulse_1ms;
    if (display_data !== 99) $fatal(1, "00.99 boundary");
    repeat (9) pulse_1ms;
    pulse_1ms;
    if (display_data !== 100) $fatal(1, "01.00 boundary");

    // Check pause and resume preserve the partial 10 ms interval.
    repeat (2) pulse_1ms;
    enable = 0;
    repeat (20) pulse_1ms;
    if (display_data !== 100 || dut.r_ms_divider !== 2)
      $fatal(1, "pause did not preserve time fraction");
    enable = 1;
    repeat (7) pulse_1ms;
    if (display_data !== 100) $fatal(1, "incremented before resumed 10 ms boundary");
    pulse_1ms;
    if (display_data !== 101) $fatal(1, "resume fraction");

    // Check clear and rollover at 100 seconds.
    @(negedge clk);
    clear = 1;
    @(negedge clk);
    clear = 0;
    if (display_data !== 0) $fatal(1, "clear");
    for (i = 0; i < 99990; i = i + 1) pulse_1ms;
    if (display_data !== 9999) $fatal(1, "99.99 boundary");
    repeat (9) pulse_1ms;
    if (display_data !== 9999) $fatal(1, "rolled over before 100.00 seconds");
    pulse_1ms;
    if (display_data !== 0) $fatal(1, "100 second rollover");

    $display("PASS: 10ms resolution, SS.hh boundaries, pause/resume, clear, 100s rollover");
    $finish;
  end

  initial begin
    #3_000_000;
    $fatal(1, "watchdog timeout");
  end
endmodule
