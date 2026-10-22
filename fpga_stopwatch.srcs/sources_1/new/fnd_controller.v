`timescale 1ns / 1ps

module fnd_controller (
    input wire clk,
    input wire reset,
    input wire tick,
    input wire [13:0] display_data,
    input wire dot_on,
    output wire [7:0] seg,
    output wire [3:0] an
);

  wire [7:0] w_seg;
  wire [1:0] w_digit_sel;
  wire [3:0] w_digit_1;
  wire [3:0] w_digit_10;
  wire [3:0] w_digit_100;
  wire [3:0] w_digit_1000;

  fnd_digit_select u_fnd_digit_select (
      .clk(clk),
      .reset(reset),
      .tick(tick),
      .digit_sel(w_digit_sel)
  );

  bin_to_bcd u_bin_to_bcd (
      .display_data(display_data),
      .digit_1(w_digit_1),
      .digit_10(w_digit_10),
      .digit_100(w_digit_100),
      .digit_1000(w_digit_1000)
  );

  fnd_digit_display u_fnd_digit_display (
      .digit_sel(w_digit_sel),
      .digit_1(w_digit_1),
      .digit_10(w_digit_10),
      .digit_100(w_digit_100),
      .digit_1000(w_digit_1000),
      .seg(w_seg),
      .an(an)
  );

  // 두 번째 자리 뒤 Dot으로 MM.SS / SS.hh 구분 (active-low)
  assign seg = {~(dot_on && (w_digit_sel == 2'd2)), w_seg[6:0]};

endmodule
