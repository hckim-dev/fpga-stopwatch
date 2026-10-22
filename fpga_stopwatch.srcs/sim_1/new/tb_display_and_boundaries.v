`timescale 1ns / 1ps

module tb_display_and_boundaries;

  reg clk = 0;
  reg reset = 1;
  reg noisy_btn = 0;
  wire clean_btn;
  wire tick;
  wire synced_reset;
  reg [13:0] display_data = 0;
  wire [3:0] digit_1, digit_10, digit_100, digit_1000;
  reg [1:0] digit_sel = 0;
  wire [7:0] seg;
  wire [3:0] an;
  integer value;
  integer position;
  integer expected_digit;
  reg display_done = 0;
  reg boundary_done = 0;

  always #5 clk = ~clk;

  bin_to_bcd u_bin_to_bcd (
      .display_data(display_data),
      .digit_1(digit_1),
      .digit_10(digit_10),
      .digit_100(digit_100),
      .digit_1000(digit_1000)
  );

  fnd_digit_display u_fnd_digit_display (
      .digit_sel(digit_sel),
      .digit_1(digit_1),
      .digit_10(digit_10),
      .digit_100(digit_100),
      .digit_1000(digit_1000),
      .seg(seg),
      .an(an)
  );

  // 최소 유효 파라미터의 레지스터 폭 검증
  tick_generator #(
      .TickCount(1)
  ) u_tick_generator (
      .clk  (clk),
      .reset(reset),
      .tick (tick)
  );

  btn_debouncer #(
      .DebounceCount(1)
  ) u_btn_debouncer (
      .clk(clk),
      .reset(reset),
      .noisy_btn(noisy_btn),
      .clean_btn(clean_btn)
  );

  reset_synchronizer u_reset_synchronizer (
      .clk(clk),
      .reset(reset),
      .synced_reset(synced_reset)
  );

  function [7:0] expected_segments;
    input integer digit;
    begin
      case (digit)
        0: expected_segments = 8'hC0;
        1: expected_segments = 8'hF9;
        2: expected_segments = 8'hA4;
        3: expected_segments = 8'hB0;
        4: expected_segments = 8'h99;
        5: expected_segments = 8'h92;
        6: expected_segments = 8'h82;
        7: expected_segments = 8'hF8;
        8: expected_segments = 8'h80;
        9: expected_segments = 8'h90;
        default: expected_segments = 8'hFF;
      endcase
    end
  endfunction

  initial begin
    // 0000~9999 전체 숫자 및 네 자리 출력 검증
    for (value = 0; value < 10_000; value = value + 1) begin
      display_data = value;
      for (position = 0; position < 4; position = position + 1) begin
        digit_sel = position;
        expected_digit = (value / (10 ** position)) % 10;
        #1;
        if (seg !== expected_segments(expected_digit)) begin
          $fatal(1, "segment value=%0d position=%0d", value, position);
        end
        if (an !== (4'b1111 ^ (4'b0001 << position))) begin
          $fatal(1, "anode position=%0d", position);
        end
      end
    end
    display_done = 1;
  end

  initial begin
    #1;
    if (synced_reset !== 1) $fatal(1, "startup reset");
    @(negedge clk);
    reset = 0;
    @(posedge clk);
    #1;
    if (synced_reset !== 1 || tick !== 1) $fatal(1, "first release cycle");
    @(posedge clk);
    #1;
    if (synced_reset !== 0) $fatal(1, "second release cycle");
    @(negedge clk);
    noisy_btn = 1;
    repeat (2) @(negedge clk);
    if (clean_btn !== 0) $fatal(1, "synchronization latency");
    @(negedge clk);
    if (clean_btn !== 1) $fatal(1, "minimum debounce count");
    noisy_btn = 0;
    repeat (3) @(negedge clk);
    if (clean_btn !== 0) $fatal(1, "button release");
    #2;
    reset = 1;
    #1;
    if (synced_reset !== 1 || tick !== 0 || clean_btn !== 0) begin
      $fatal(1, "asynchronous reset");
    end
    boundary_done = 1;
  end

  initial begin
    wait (display_done && boundary_done);
    $display(
        "PASS: all 10000 display values, all digits, minimum parameters, reset synchronization");
    $finish;
  end

  initial begin
    #100_000;
    $fatal(1, "watchdog timeout");
  end

endmodule
