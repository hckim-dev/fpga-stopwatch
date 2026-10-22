`timescale 1ns / 1ps

module bin_to_bcd (
    input  wire [13:0] display_data,
    output wire [ 3:0] digit_1,
    output wire [ 3:0] digit_10,
    output wire [ 3:0] digit_100,
    output wire [ 3:0] digit_1000
);

  assign digit_1 = display_data % 10;
  assign digit_10 = (display_data / 10) % 10;
  assign digit_100 = (display_data / 100) % 10;
  assign digit_1000 = (display_data / 1000) % 10;

endmodule
