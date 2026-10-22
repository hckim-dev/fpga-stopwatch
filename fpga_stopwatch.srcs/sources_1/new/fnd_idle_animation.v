`timescale 1ns / 1ps

module fnd_idle_animation #(
    parameter integer IdleTimeMs = 5_000,
    parameter integer AnimationStepMs = 100
) (
    input wire clk,
    input wire reset,
    input wire tick_1ms,
    input wire paused,
    input wire button_active,
    output wire active,
    output reg [7:0] seg
);

  localparam integer IdleCountWidth = $clog2(IdleTimeMs + 1);

  localparam integer StepCountWidth = (AnimationStepMs > 1) ? $clog2(AnimationStepMs) : 1;

  reg [IdleCountWidth-1:0] r_idle_count;
  reg [StepCountWidth-1:0] r_step_count;
  reg [2:0] r_step;

  // 버튼 입력 중 대기 시간 초기화, 대기 완료 후 포화 상태 유지
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r_idle_count <= 0;
      r_step_count <= 0;
      r_step       <= 0;
    end else if (!paused || button_active) begin
      r_idle_count <= 0;
      r_step_count <= 0;
      r_step       <= 0;
    end else if (tick_1ms) begin
      if (r_idle_count < IdleTimeMs) begin
        r_idle_count <= r_idle_count + 1;
      end else if (r_step_count == AnimationStepMs - 1) begin
        r_step_count <= 0;
        if (r_step == 5) begin
          r_step <= 0;
        end else begin
          r_step <= r_step + 1;
        end
      end else begin
        r_step_count <= r_step_count + 1;
      end
    end
  end

  // 버튼 인식 시 시간 표시 복귀 및 기존 버튼 기능 수행
  assign active = paused && !button_active && (r_idle_count == IdleTimeMs);

  // active-low {DP,g,f,e,d,c,b,a}, a → b → c → d → e → f 시계 방향 회전
  always @(*) begin
    case (r_step)
      0: seg = 8'hFE;
      1: seg = 8'hFD;
      2: seg = 8'hFB;
      3: seg = 8'hF7;
      4: seg = 8'hEF;
      5: seg = 8'hDF;
      default: seg = 8'hFF;
    endcase
  end

endmodule
