`timescale 1ns / 1ps

module fnd_digit_select (
    input wire clk,
    input wire reset,
    input wire tick,
    output reg [1:0] digit_sel
);

  // 100 MHz 클럭 기반 1 ms tick마다 다음 자리 선택
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      digit_sel <= 0;
    end else if (tick) begin
      digit_sel <= digit_sel + 1;
    end
  end

endmodule
