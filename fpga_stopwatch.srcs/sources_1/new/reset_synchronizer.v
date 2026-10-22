`timescale 1ns / 1ps

module reset_synchronizer (
    input  wire clk,
    input  wire reset,
    output wire synced_reset
);
  // FPGA 구성 직후 2클럭 초기화 유지
  (* ASYNC_REG = "TRUE" *) reg [1:0] r_reset_sync = 2'b11;

  // 리셋 비동기 인가 및 동기 해제
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r_reset_sync <= 2'b11;
    end else begin
      r_reset_sync <= {r_reset_sync[0], 1'b0};
    end
  end

  assign synced_reset = r_reset_sync[1];

endmodule
