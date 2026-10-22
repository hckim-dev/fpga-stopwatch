# FPGA Stopwatch

Basys3 보드와 Verilog로 구현한 분초 시계 및 스톱워치 학습 프로젝트입니다. 분초 시계는 `MM.SS` 형식으로 표시하고, 스톱워치는 실행·일시정지·초기화를 지원합니다. 일시정지 후 5초 동안 조작이 없으면 FND에 원형 애니메이션이 나타납니다.

> 학습 프로젝트이며, RTL 작성과 검토 과정에서 AI 도구를 보조적으로 사용했습니다. 주요 동작은 Vivado 시뮬레이션으로 확인했습니다.

## 주요 기능

- Basys3 100 MHz 입력 클럭에서 1 ms tick 생성
- 분초 시계: 59:59 다음 00:00 순환, Dot 1 Hz 점멸
- 스톱워치: 1 ms 내부 계수, MM.SS 표시, 일시정지 시 소수 시간 보존
- 일시정지 후 5초 무입력 시 6개 FND 바깥 선분 원형 애니메이션
- 버튼 디바운스 완료 후 애니메이션 종료 및 버튼 기능 수행
- 버튼 2단 동기화, 디바운스, 상승 에지 검출
- 4자리 FND 멀티플렉싱 및 십진수 표시

## 버튼 조작

| 입력 | 기능 |
|---|---|
| SW15 | 전체 리셋 |
| 왼쪽 버튼 `btn[0]` | 분초 시계와 스톱워치 전환 |
| 가운데 버튼 `btn[1]` | 스톱워치 00:00 초기화, 일시정지 상태 유지 |
| 오른쪽 버튼 `btn[2]` | 스톱워치 일시정지와 재개 |

LED[0]은 분초 시계, LED[1]은 스톱워치 실행, LED[2]는 일시정지 상태를 표시합니다. 분초 시계는 스톱워치 화면에서도 계속 진행합니다.

## 설계 구조

```text
top_minsec_stopwatch
├── reset_synchronizer
├── tick_generator
├── btn_debouncer × 3
├── minsec_stopwatch
│   └── minsec_counter × 2
├── fnd_idle_animation
└── fnd_controller
    ├── fnd_digit_select
    ├── bin_to_bcd
    └── fnd_digit_display
```

모든 순차 회로는 100 MHz `clk`를 사용합니다. `tick`은 카운터 동작 허가 신호이며 별도의 느린 클럭으로 사용하지 않습니다. 상세 상태도, 핀 배치, 검증 범위는 [`docs/verification.md`](docs/verification.md)를 참고하세요.

## Vivado에서 실행

1. Vivado 2026.1에서 `fpga_stopwatch.xpr`을 엽니다.
2. Design Sources의 `top_minsec_stopwatch`를 합성 top으로 사용합니다.
3. `tb_top_minsec_stopwatch`, `tb_fnd_idle_animation`, `tb_display_and_boundaries`를 각각 Simulation Top으로 선택해 Behavioral Simulation의 Run All을 실행합니다.
4. 구현 결과는 Basys3 `xc7a35tcpg236-1` 기준입니다.

일괄 검증은 저장소 루트에서 아래 명령으로 실행할 수 있습니다.

```powershell
vivado -mode batch -source scripts/verify_project.tcl
```

## 검증 상태

- 3개 테스트벤치 통과
- 합성, 배치·배선, DRC, 비트스트림 생성 완료
- 내부 100 MHz 타이밍 제약 충족
- 실제 Basys3에 비트스트림을 다운로드한 동작은 아직 검증하지 않았습니다.

## 구현 도구

- AMD Vivado 2026.1
- Basys3, Artix-7 `xc7a35tcpg236-1`
- Verilog HDL

## 라이선스 및 출처

별도 오픈소스 라이선스는 아직 지정하지 않았습니다. Basys3 핀 제약은 Digilent Basys-3 Master XDC를 바탕으로 이 설계의 포트에 맞게 정리했습니다.
