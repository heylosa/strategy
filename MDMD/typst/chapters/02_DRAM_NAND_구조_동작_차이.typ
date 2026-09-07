#import "../template.typ": callout

= 02. DRAM과 NAND: 구조·동작·차이

== 1. 한눈에 보기

=== 1.1 왜 PE에게 중요한가

- PE가 책임지는 제품은 결국 DRAM 또는 NAND(그리고 DRAM을 쌓은 HBM)다. 셀이 어떻게 생겼고 어떻게 읽고 쓰는지 모르면 테스트 fail 항목(tWR, retention, program fail, read disturb)이 무엇을 뜻하는지 해석할 수 없다.
- 두 메모리는 "저장 원리"가 근본적으로 다르다. DRAM은 커패시터에 전하를 담고, NAND는 트랩층에 전하를 넣어 트랜지스터 V\_th를 바꾼다. 이 차이가 공정 모듈, 대표 불량, 테스트 방법, 스케일링 방향까지 전부 갈라놓는다.
- 타이밍 파라미터(tRCD, tRFC)와 NAND 동작 파라미터(tPROG, tR, P/E cycle)는 각각 물리적 원인이 있다. 파라미터 하나가 규격을 벗어나면 어떤 공정 변수가 움직였는지 거꾸로 추적하는 것이 PE의 일이다.
- 미래 방향(3D DRAM, 4F², IGZO, 300단 이상 NAND, 웨이퍼 본딩)은 면접 심화 질문의 단골이다. 왜 그 방향인지를 물리로 말할 수 있어야 한다.
- A!SK에서 "DRAM과 NAND의 차이를 설명하라"는 가장 흔한 문항이다. 1분 안에 구조·원리·휘발성·용도·공정 난이도를 짚을 수 있어야 한다.

=== 1.2 핵심 키워드

#table(
  columns: 2,
  align: left,
  table.header(
    [*용어*],
    [*한 줄 정의*],
  ),
  [1T1C],
  [DRAM 셀: 트랜지스터 1개 + 커패시터 1개. 전하 유무가 데이터],
  [6F²],
  [현 DRAM 셀 면적. F = 최소 half pitch. 2F × 3F 배치],
  [BCAT],
  [매립 채널 어레이 트랜지스터. WL을 Si 표면 아래에 묻어 SCE와 커플링을 줄임],
  [센스앰프(SA)],
  [BL 쌍의 미세 전압 차(수십 mV)를 증폭해 0/1 판정하는 래치],
  [전하 공유(charge sharing)],
  [셀 커패시터와 BL 용량이 전하를 나눠 ΔV = ΔV\_cell·C\_s/(C\_s + C\_BL)],
  [tRCD, tRP, tRAS, tWR, tRFC],
  [DRAM 타이밍 파라미터. 각각 WL 활성화→데이터, 프리차지, 행 활성 시간, 쓰기 복구, refresh 시간],
  [Retention, VRT],
  [데이터 유지 시간과 그것이 시간에 따라 요동치는 현상],
  [Row hammer],
  [인접 행을 반복 활성화하면 피해 행 전하가 빠지는 disturb],
  [CTF(charge trap flash)],
  [SiN 트랩층에 전하를 저장하는 NAND 셀. 3D NAND 주력],
  [ONO],
  [블로킹 산화막 / 트랩 질화막 / 터널 산화막 3층 게이트 스택],
  [FN 터널링, ISPP],
  [고전계 산화막 터널링과 단계적 전압 증가 프로그램 방식],
  [String, page, block],
  [NAND 어레이 단위: 직렬 셀 열, 동시 read/program 단위, erase 단위],
  [TLC/QLC],
  [셀당 3비트(8상태)/4비트(16상태) 저장. read margin과 endurance trade-off],
  [Disturb],
  [program/pass/read 시 비선택 셀이 받는 의도치 않은 V\_th 변화],
  [PUC/CoP, 웨이퍼 본딩],
  [주변회로를 셀 아래에 두거나 별도 웨이퍼로 만들어 본딩하는 3D NAND 구조],
)

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 2. 기초

=== 2.1 메모리 분류와 두 가지 저장 원리

```text
반도체 메모리
 +-- 휘발성(전원 끄면 소실)
 |     +-- SRAM: 6T 래치, 가장 빠름, 셀 크기 큼(캐시)
 |     +-- DRAM: 1T1C, 커패시터 전하, refresh 필요(메인 메모리, HBM, 그래픽)
 +-- 비휘발성
       +-- NAND Flash: 트랜지스터 V_th에 저장, 블록 erase(SSD, 모바일 저장)
       +-- NOR Flash: 셀 병렬 연결, 랜덤 read 빠름(코드 저장)
       +-- 신메모리: MRAM, RRAM, PCM, FeRAM(니치·임베디드)
```

두 저장 원리:

#table(
  columns: 3,
  align: left,
  table.header(
    [*항목*],
    [*DRAM(전하량 저장)*],
    [*NAND(V\_th 변조)*],
  ),
  [정보의 물리량],
  [커패시터에 담긴 전하 Q(약 수 fC)],
  [트랩층 전하가 만드는 트랜지스터 V\_th(수 V 창)],
  [읽기 방법],
  [전하를 BL로 꺼내 전압 차 감지(파괴적 읽기 → 재기록)],
  [게이트에 읽기 전압을 걸고 채널 전류 유무 감지(비파괴)],
  [쓰기 방법],
  [BL 전압을 셀에 전달(ns)],
  [FN 터널링으로 전하 주입/제거(μs~ms)],
  [유지],
  [누설로 수십 ms~수 s → refresh],
  [산화막 장벽 → 수 년(고온 가속 시 단축)],
  [열화],
  [사실상 무한 쓰기(10^15 이상)],
  [터널 산화막 손상 → 1천~10만 회 P/E],
)

#callout("핵심")[DRAM은 "전하가 있느냐"를 빨리 읽고 쓰지만 새어 나간다. NAND는 "장벽 안에 전하를 가둬" 오래 유지하지만 넣고 빼는 데 높은 전압과 시간이 들고 장벽이 상한다. 모든 차이는 이 한 문장에서 파생된다.]

=== 2.2 DRAM 셀 기초: 1T1C

```text
        WL (word line)
         |
     +---+---+
BL --| 셀 Tr  |---+ 저장 노드(SN)
     +-------+   |
               -----  C_s (셀 커패시터, 약 10 fF)
               -----
                 |
               V_plate (보통 V_core/2)
```

- 셀 트랜지스터: WL이 게이트, BL이 한쪽 S/D, 저장 노드가 다른 쪽. 켜면 BL과 커패시터가 연결된다.
- 커패시터: 한 전극은 저장 노드, 다른 전극은 전체 셀이 공유하는 플레이트(plate). 플레이트 전압을 V\_core/2로 두면 유전체에 걸리는 최대 전압이 V\_core/2로 줄어 누설과 신뢰성이 유리하다.
- 데이터 1: 저장 노드 V\_core(예: 1.0~1.1 V). 데이터 0: 0 V. 유전체에는 ±V\_core/2가 걸린다.

#callout("예시")[C\_s = 10 fF, V\_core = 1.0 V → 저장 전하 Q = 10 fC = 6.2×10^4개 전자. 누설 10 fA면 1초에 10 fC, 즉 1 s 만에 전부 사라진다. 64 ms 안에 절반 이상 남으려면 셀당 누설이 약 80 fA 이하여야 하고, 실제 대부분 셀은 fA 이하지만 tail 셀이 문제다.]

=== 2.3 NAND 셀 기초: 부동 게이트와 전하 트랩

```text
   [Floating Gate 셀]                [Charge Trap(CTF) 셀]
    제어 게이트(WL)                     제어 게이트(WL, W)
   +--------------+                   +--------------+
   | IPD(ONO)     |  블로킹            | 블로킹 산화막(Al2O3/SiO2)
   +--------------+                   +--------------+
   | poly FG      |  전하 저장(도체)   | SiN 트랩층    |  전하 저장(절연체 트랩)
   +--------------+                   +--------------+
   | 터널 산화막   |  약 7~8 nm        | 터널 산화막   |  약 4~6 nm(밴드 엔지니어링)
   +--------------+                   +--------------+
   |   Si 채널    |                   |  poly-Si 채널 |
```

- 전자를 저장층에 넣으면 채널 위 전위가 낮아져 V\_th가 올라간다(programmed, 보통 "0"). 빼면 V\_th가 내려간다(erased, "1").
- 읽기: 게이트에 두 상태 사이 전압을 걸어 채널이 켜지는지 본다. 켜지면 erased.
- ΔV\_th ≈ Q\_stored / C\_blocking. 저장층에 전자 1개가 늘 때 ΔV\_th는 셀 면적에 반비례한다.

#callout("예시")[2D 15 nm급 FG 셀에서 프로그램 상태 전자 수는 수십 개 수준이었다. 전자 1개 = 수십 mV 변화. 3D CTF 셀은 채널 홀 둘레 전체가 셀이라 면적이 커서(예: 둘레 π × 100 nm × 게이트 높이 30 nm ≈ 9400 nm²) 전자 수백~수천 개로 여유가 생겼다. 이것이 3D 전환의 핵심 이득 중 하나다.]

=== 2.4 어레이 조직 기초

#table(
  columns: 3,
  align: left,
  table.header(
    [*단위*],
    [*DRAM*],
    [*NAND*],
  ),
  [최소 접근],
  [1비트(셀)이지만 실제로는 행(row) 전체가 SA에 열림],
  [페이지(page): 한 WL의 셀 집합, 4~16 KB + 여분],
  [행/열],
  [WL(row) × BL(column), 서브어레이 512~1024 WL × 수백~천 BL],
  [WL × 스트링, 블록 안 WL 수 = 단 수(100~300)],
  [소거 단위],
  [없음(덮어쓰기)],
  [블록(block): 수십 MB, 수천 페이지],
  [상위 조직],
  [뱅크(bank) 16~32개 → 뱅크 그룹 → 채널],
  [플레인(plane) 2~6개 → 다이 → 패키지],
  [병렬성],
  [뱅크 인터리빙],
  [플레인 병렬, 다이 병렬(채널당 4~8 다이)],
  [접근 시간],
  [수십 ns 랜덤],
  [read 수십 μs, program 수백 μs~ms, erase ms],
)

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 3. 구조·동작 상세

=== 3.1 DRAM 셀 어레이: 6F² 레이아웃과 BCAT

F(feature size)는 최소 half pitch다. 셀 면적을 F²의 배수로 표현한다.

#table(
  columns: 4,
  align: left,
  table.header(
    [*레이아웃*],
    [*셀 면적*],
    [*BL 구조*],
    [*시대*],
  ),
  [8F²],
  [2F × 4F],
  [folded BL(BL과 /BL이 같은 어레이)],
  [90 nm 이전],
  [6F²],
  [2F × 3F],
  [open BL(BL과 /BL이 인접 어레이)],
  [현재 주력(2000년대 후반~)],
  [4F²],
  [2F × 2F],
  [수직 채널 트랜지스터 필요],
  [개발 중],
)

6F² 어레이: 활성 영역(active)이 WL에 대해 비스듬히(약 20~30°) 놓이고, 하나의 활성 영역이 두 셀을 이루며 가운데 BL 콘택을 공유한다. 두 WL이 활성 영역을 가로지르고, 양 끝에 저장 노드 콘택(SNC)이 붙는다.

```text
  6F^2 셀 어레이 평면 개념 (WL: 가로, BL: 세로, 활성영역 비스듬)

   WL0 ====================================
         \\   SNC    BLC    SNC   /
   WL1 ====================================
           \\  활성 영역(2셀 공유) /
   WL2 ====================================
        |       |       |       |
       BL0     BL1     BL2     BL3

   한 활성 영역: SNC - Tr(WL_a) - BLC(공유) - Tr(WL_b) - SNC
```

BCAT(buried channel array transistor, buried word line) 도입 이유:

#table(
  columns: 2,
  align: left,
  table.header(
    [*문제(planar 셀 Tr)*],
    [*BCAT의 해결*],
  ),
  [L이 F 수준으로 짧아져 SCE·누설 폭증],
  [채널을 Si에 리세스(깊이 100~200 nm)해 유효 채널 길이 = 리세스 둘레로 확장],
  [WL이 Si 위에 있어 BL·SNC와 커플링, 높이 증가],
  [WL(W)을 트렌치 안에 묻어 표면 평탄화, BL 커패시턴스·WL-BL 커플링 감소],
  [게이트 한 면 제어 → DIBL 큼],
  [리세스 채널 3면 제어(saddle fin 형태), SS·DIBL 개선],
  [고농도 채널 도핑 필요 → 접합 누설·RDF],
  [채널 도핑 낮추고 금속 WL 일함수로 V\_th 설정],
  [WL poly 저항 큼],
  [W 매립 WL로 저항 저감, 단 W와 산화막 사이 TiN 배리어],
)

BCAT의 새로운 과제: 매립 WL(W, 일함수 약 4.5~4.6 eV)이 접합과 오버랩되는 부분에서 GIDL이 커진다. 대책으로 WL 상부(접합 근처)는 일함수가 낮은 n⁺ poly, 하부는 W로 구성하는 이중 일함수 게이트(dual work-function)를 쓴다. 접합 근처 전계를 낮춰 GIDL을 줄이면서 채널 하부는 금속으로 V\_th를 확보한다.

#callout("예시")[리세스 깊이 150 nm, WL 폭 20 nm면 유효 채널 길이는 리세스 양 측벽과 바닥을 합쳐 300 nm 이상이다. 같은 평면 면적에 L 20 nm planar를 만들었다면 DIBL 100 mV/V 이상, punch-through로 셀로 쓸 수 없다. 리세스 깊이가 10 nm 얕아지면 유효 L이 약 7% 줄어 V\_th가 수십 mV 내려가고 I\_off가 수 배 는다. 그래서 리세스 에치 깊이는 어레이 핵심 SPC 항목이다.]

=== 3.2 비트라인과 센스앰프

```text
 [Folded BL]                        [Open BL]
   어레이 A                           어레이 A      어레이 B
   BL  ---o---o---o---+               BL ---o---o---+   +---o---o--- /BL
   /BL ---o---o---o---+ SA            (SA는 두 어레이 사이에서 BL, /BL 비교)
   (BL과 /BL이 같은 어레이,                              +--SA--+
    같은 노이즈 → 공통모드 제거)
   셀 8F^2                            셀 6F^2 (BL 피치당 셀 밀도 높음)
   노이즈 강함                       노이즈 취약, 어레이 끝에 더미 어레이 필요
```

센스앰프 동작(전형적 순서):

+ 프리차지: BL과 /BL을 V\_BL = V\_core/2로 등화(equalize).
+ WL 활성(ACT): 선택 셀 Tr on → 전하 공유 → BL이 ±ΔV만큼 움직임.
+ 센싱: 교차 결합 래치(cross-coupled inverter)에 전원(SAP/SAN) 인가 → ΔV가 V\_core/0으로 증폭. 이때 셀에도 원래 데이터가 완전 전압으로 복원(restore)됨.
+ 열 선택(RD/WR): 컬럼 선택선(CSL)으로 원하는 BL을 데이터 라인에 연결.
+ 프리차지(PRE): WL off 후 BL 등화. 다음 ACT 준비.

SA 오프셋: 두 인버터 트랜지스터의 V\_th 불일치(mismatch)가 그대로 감지 한계다. σV\_th 10~15 mV면 3σ 오프셋 30~45 mV. 셀이 만드는 ΔV가 이보다 충분히 커야 한다. 오프셋 보상(offset cancellation) 회로를 넣기도 한다.

=== 3.3 셀 커패시터 구조

```text
 [Cylinder(양면 사용)]        [Pillar(외면만)]
   plate(TiN)                  plate(TiN)
 +--+  +--+  +--+            +----+ +----+
 |  |  |  |  |  |            |####| |####|  <- 저장 노드(TiN 채움)
 |  |  |  |  |  |  ZAZ 유전체  |####| |####|
 |  |  |  |  |  |  안팎 도포   |####| |####|  ZAZ는 외면만
 +--+  +--+  +--+            +----+ +----+
  |SNC|  |SNC|                |SNC|  |SNC|
 --------- 서포터(SiN) 1~3겹로 이웃 기둥끼리 지지, 쓰러짐 방지 ---------
```

#table(
  columns: 3,
  align: left,
  table.header(
    [*요소*],
    [*재료/치수(대략)*],
    [*역할·이슈*],
  ),
  [저장 노드 전극],
  [TiN, 두께 수 nm(실린더) 또는 채움(필러)],
  [저항(tWR), 표면 거칠기(누설), 산소 확산 배리어],
  [유전체],
  [ZAZ(ZrO₂/Al₂O₃/ZrO₂) 총 5~7 nm, κ 30~40],
  [ZrO₂ 정방정 결정화로 κ 확보, Al₂O₃로 누설 차단·결정립 제어],
  [플레이트 전극],
  [TiN(+ 도핑 poly 또는 W 보강)],
  [전체 셀 공유, 저항 낮아야 노이즈 억제],
  [높이],
  [1~1.5 μm 이상, aspect ratio 50~100],
  [HAR 에치 난이도(bowing, twisting), 쓰러짐(leaning)],
  [서포터],
  [SiN 1~3층, 측면 연결],
  [습식 몰드 제거 시 기둥 지지, 서포터 오픈 면적이 C\_s 손실],
  [지름],
  [30~40 nm급],
  [지름 줄면 실린더 내부 공간 부족 → 필러 전환],
)

실린더는 안팎 양면을 쓰므로 면적이 2배지만, 지름이 30 nm대로 줄면 내부에 유전체 5 nm + 플레이트를 채울 공간이 부족해 외면만 쓰는 필러로 간다. 필러는 면적이 절반이라 높이나 κ로 보상해야 한다.

#callout("면접")["DRAM 커패시터를 왜 그렇게 높이 세웁니까?" → 결론: 셀 면적은 줄어드는데 C\_s는 10 fF 수준을 유지해야 하기 때문입니다. 근거: C = ε₀κA/d에서 d는 누설 때문에 5 nm 아래로 더 못 줄이고 κ도 밴드갭 trade-off로 한계가 있어, 남은 변수 A를 수직 높이로 확보합니다. 예시: 지름 35 nm 실린더가 15 fF을 내려면 높이 1 μm 이상, aspect ratio 50~100이 필요하고, 그래서 HAR 에치의 bowing이나 기둥 쓰러짐이 DRAM 대표 공정 난제가 되며 서포터 층이 도입되었습니다.]

=== 3.4 DRAM 동작: read/write/refresh와 전하 공유 계산

Read(파괴적 읽기 + 복원):

```text
 프리차지: V_BL = V_core/2 = 0.5 V (V_core = 1.0 V 가정), C_BL = 40 fF
 셀 "1": V_SN = 1.0 V, C_s = 10 fF

 전하 공유 후 BL 전압:
   V_BL' = (C_s·V_SN + C_BL·V_BL) / (C_s + C_BL)
         = (10×1.0 + 40×0.5) / 50 = 30/50 = 0.60 V   →  ΔV = +100 mV
 셀 "0": V_SN = 0 V
   V_BL' = (0 + 20) / 50 = 0.40 V                      →  ΔV = −100 mV

 일반식: ΔV = (V_SN − V_BL) · C_s / (C_s + C_BL)
 SA가 ΔV를 감지해 BL을 1.0 V 또는 0 V로 증폭 → 셀도 복원됨(restore)
```

#table(
  columns: 3,
  align: left,
  table.header(
    [*조건 변화*],
    [*ΔV*],
    [*의미*],
  ),
  [기준(C\_s 10, C\_BL 40, V\_SN 1.0)],
  [100 mV],
  [오프셋 30 mV 대비 여유],
  [누설로 V\_SN 0.7 V],
  [40 mV],
  [마진 소진 직전(retention 한계)],
  [C\_s 6 fF],
  [65 mV],
  [처음부터 마진 부족, retention 짧아짐],
  [C\_BL 60 fF(BL 길어짐)],
  [71 mV],
  [서브어레이 크게 만들면 손해],
  [V\_core 0.9 V],
  [90 mV],
  [저전압화가 센싱 마진을 갉아먹음],
)

Write: ACT로 행을 열어 SA가 데이터를 잡은 뒤, 쓰기 데이터로 SA를 뒤집고 BL 전압이 셀 Tr을 통해 저장 노드를 충전한다. 셀 Tr이 on이어도 "1"을 쓸 때 V\_GS = V\_WL − V\_SN이 줄어 전류가 감소하므로 WL은 V\_core보다 높은 V\_PP(예: 2.5~3 V)로 부스트한다. 쓰기 완료에 필요한 시간이 tWR의 물리적 근거다.

Refresh: 모든 행을 tREF(64 ms, 고온 32 ms) 안에 한 번씩 ACT-PRE 해서 복원. 행이 8192개면 tREFI = 64 ms / 8192 = 7.8 μs(DDR4). DDR5는 3.9 μs(refresh 명령을 더 잦게, 한 번에 적게). Refresh 동안 해당 뱅크는 접근 불가 → 성능·전력 손실. 16 Gb 다이에서 refresh 전력은 대기 전력의 상당 부분이다.

=== 3.5 타이밍 파라미터와 물리적 의미

#table(
  columns: 4,
  align: left,
  table.header(
    [*파라미터*],
    [*정의*],
    [*대략 값(DDR5-4800)*],
    [*물리적 결정 요인*],
  ),
  [tRCD],
  [ACT → RD/WR 가능까지],
  [약 16 ns],
  [WL RC 상승 + 셀 Tr on + 전하 공유 + SA 센싱 시간],
  [tRP],
  [PRE → 다음 ACT까지],
  [약 16 ns],
  [WL 하강(RC) + BL 등화 시간],
  [tRAS],
  [ACT → PRE 가능까지],
  [약 32 ns],
  [센싱 + 셀 복원(restore) 완료까지],
  [tRC],
  [tRAS + tRP, 행 사이클],
  [약 48 ns],
  [위 둘의 합],
  [tWR],
  [마지막 쓰기 데이터 → PRE],
  [약 30 ns],
  [SA 뒤집기 + 셀 노드 충전 τ = (R\_c + R\_ch)·C\_s 다수 배],
  [tRFC],
  [REF 명령 → 다음 명령],
  [16 Gb 약 295 ns(RFC1)],
  [동시 refresh 행 수 × tRC + 전력 제한],
  [tREFI],
  [평균 refresh 간격],
  [3.9 μs(DDR5), 7.8 μs(DDR4)],
  [64 ms / refresh 명령 수, 고온 시 절반],
  [tCCD],
  [연속 컬럼 명령 간격],
  [수 tCK],
  [데이터 경로·프리페치],
  [tAA/CL],
  [RD → 데이터 출력],
  [약 16 ns(CL40 at 4800)],
  [컬럼 경로 + I/O],
)

#callout("예시")[tRCD가 규격 16 ns인데 특정 행 그룹에서 17 ns가 나온다면: (a) 그 행들의 WL 저항이 높다(W 매립 채움 보이드), (b) 셀 Tr V\_th가 높아 on 전류가 작다(리세스 깊이·일함수), (c) C\_s가 작아 ΔV가 작고 SA 센싱이 느리다. fail 행이 서브어레이 끝(WL 드라이버에서 먼 쪽)에 몰리면 (a), 웨이퍼 에지에 몰리면 (b)·(c)의 공정 균일도 문제로 가설을 좁힌다.]

=== 3.6 Retention, VRT, row hammer, GIDL

Retention: 셀이 데이터를 유지하는 시간. 분포는 평균 수 s이지만 tail이 두껍다(1장 3.10). 규격은 85°C에서 64 ms. 실제 제품은 tail 셀을 리던던시로 repair하고, DDR5는 on-die ECC(128비트당 8비트 SEC)로 산발적 1비트 fail을 구제한다.

누설 경로별 비중(대략적 경향):

#table(
  columns: 4,
  align: left,
  table.header(
    [*경로*],
    [*지배 조건*],
    [*온도 의존*],
    [*공정 연결*],
  ),
  [셀 Tr subthreshold],
  [V\_th 낮은 셀, 고온],
  [강함],
  [리세스 깊이, 일함수, 도핑],
  [GIDL],
  [음 WL off 전압 클 때, 오버랩 트랩],
  [약~중],
  [WL-접합 오버랩, 이중 일함수, 계면],
  [접합 누설(SRH/TAT)],
  [결함·오염 있는 소수 셀],
  [강함(E\_a 0.5~0.6)],
  [오염, 주입 결함, 어닐],
  [커패시터 유전체 누설],
  [유전체 얇음·결함],
  [중],
  [ZAZ 두께, Al₂O₃ 결손, 전극 거칠기],
  [BL·인접 셀 disturb],
  [특정 접근 패턴],
  [-],
  [커플링 용량, 격리],
)

VRT(variable retention time): 같은 셀의 retention이 두 상태(예: 2 s ↔ 100 ms) 사이를 무작위로 왕복하는 현상. 공핍층 내 단일 결함(트랩)의 전하 상태가 바뀌면서 생성 누설이 켜지고 꺼지는 것으로 설명된다(random telegraph 성격). 테스트 시점에 "좋은 상태"였던 셀이 필드에서 "나쁜 상태"로 바뀌면 스크린을 통과한 fail이 된다. 완전 스크린이 불가능해 ECC와 마진 refresh가 필수이고, 고온·전계 스트레스로 상태 전환을 유도해 스크린하는 방법이 연구된다.

Row hammer: 한 WL(aggressor)을 짧은 시간에 수만 회 이상 반복 ACT/PRE하면 인접 WL(victim) 셀의 전하가 빠진다. 기구는 여러 가지가 제안된다: WL 토글에 의한 인접 채널 커플링과 전자 주입, WL 스윙 시 생성된 캐리어의 확산, 인접 게이트 전계에 의한 소수 캐리어 이동. 셀 피치가 줄수록 한계 횟수가 낮아진다(DDR3 시절 십만 회대 → 최신 세대 수천~수만 회).

대책: (a) 회로: TRR(target row refresh), RFM(refresh management), DDR5 PRAC(per-row activation counting, 행별 카운터로 임계 초과 시 인접 행 refresh 요청), (b) 공정: 격리 강화, WL 간 커플링 저감, 접합 프로파일, (c) 시스템: 컨트롤러가 접근 패턴 감시.

GIDL은 DRAM에서 두 얼굴을 가진다. 셀 Tr에서는 retention을 깎는 적이지만, 음 WL 전압에 의한 subthreshold 억제와 trade-off로 최적점이 있다(1장 3.5). 이중 일함수 WL, 오버랩 축소, 접합 완화가 대책이다.

#callout("주의")["retention이 나쁘다"는 말은 원인을 특정하지 않는다. 데이터를 볼 때 (1) tail 셀 수, (2) 온도 의존(E\_a), (3) V\_WL(off) 의존, (4) 다이 내 위치(WL 위치, 서브어레이 에지), (5) 데이터 패턴 의존(인접 셀 상태)을 항상 함께 정리하라. 이 다섯이 GIDL·접합·커패시터·disturb를 가르는 기준이다.]

=== 3.7 주변회로(core/peri)

#table(
  columns: 3,
  align: left,
  table.header(
    [*영역*],
    [*구성*],
    [*PE 관점 이슈*],
  ),
  [셀 어레이(cell)],
  [BCAT + 커패시터, 6F²],
  [retention, tWR, 셀 V\_th 산포],
  [코어(core)],
  [SA, sub-WL 드라이버(SWD), 컬럼 디코더, 로컬 I/O],
  [SA 오프셋(σV\_th), SWD 구동력(tRCD), 어레이 에지 효과],
  [주변(peri)],
  [명령/주소 디코더, 전압 생성기(V\_PP, V\_BB, V\_core), DLL/PLL, I/O 버퍼, 테스트 로직],
  [고속 트랜지스터 I\_on, 게이트 누설(대기 전력), ESD, I/O 타이밍],
)

WL 드라이버는 V\_PP(약 2.5~3 V)로 WL을 끌어올리고, off 시 음 전압(V\_BB2, −0.2~−0.4 V)으로 내린다. 그래서 고전압 트랜지스터(두꺼운 게이트 산화막)가 필요하다. 주변회로는 셀보다 트랜지스터 다양성이 커서(고전압, 저전압 고속, I/O) 게이트 산화막 3종 이상, V\_th 조절 주입 다수가 들어간다.

셀 어레이 위에 커패시터가 1 μm 넘게 서 있으므로 주변회로와 어레이 사이에 큰 높이 차가 생긴다. 이를 메우는 층간 절연막 증착·CMP, 깊은 콘택이 DRAM 후공정의 특징이다.

=== 3.8 DRAM 제품군 비교

#table(
  columns: 5,
  align: left,
  table.header(
    [*항목*],
    [*DDR5*],
    [*LPDDR5X*],
    [*GDDR7*],
    [*HBM3E*],
  ),
  [핀당 속도(대략)],
  [4800~8800 MT/s],
  [8533~9600 MT/s],
  [32~40 Gbps(PAM3)],
  [약 9.2~9.8 Gbps],
  [I/O 폭],
  [다이 x4/x8/x16, 모듈 2×32 bit 채널],
  [채널당 x16(다이 x16/x32)],
  [다이 x32],
  [스택당 1024 bit(16채널)],
  [스택당/모듈당 대역폭],
  [DIMM 약 38~70 GB/s],
  [패키지 약 68~77 GB/s],
  [다이당 128~160 GB/s],
  [스택당 약 1.2 TB/s],
  [전압(대략)],
  [VDD 1.1 V],
  [VDD2H 1.05 V, VDDQ 0.5 V(0.3 V 옵션)],
  [1.2 V],
  [1.1 V],
  [신호 방식],
  [NRZ, DFE],
  [NRZ],
  [PAM3],
  [NRZ, 2.5D 인터포저],
  [특징],
  [on-die ECC, 뱅크 그룹, DFE],
  [저전력 모드, DVFS, WCK],
  [그래픽 대역폭, 온다이 ECC],
  [TSV 8~16단 적층, 베이스 다이, 열 관리],
  [용도],
  [서버·PC 메인 메모리],
  [모바일·노트북·차량],
  [GPU·콘솔],
  [AI 가속기·HPC],
  [PE 관심],
  [고온 retention, 리프레시 전력],
  [저전압 센싱 마진, 저전력 모드 누설],
  [초고속 I/O 지터, 열],
  [TSV 수율, 적층 후 열·기계 스트레스, KGD 테스트],
)

HBM4는 I/O 2048 bit, 스택당 약 2 TB/s, 베이스 다이를 로직 파운드리 공정으로 만드는 방향이며, 하이브리드 본딩 적층이 검토된다.

=== 3.9 DRAM 미래 방향

#table(
  columns: 4,
  align: left,
  table.header(
    [*방향*],
    [*내용*],
    [*이득*],
    [*과제*],
  ),
  [4F² VCT],
  [수직 채널 트랜지스터, WL이 채널을 감쌈, BL 아래],
  [셀 면적 33% 축소],
  [floating body, WL 간 커플링, 소스 접합 형성, 커패시터 정렬],
  [3D DRAM(VS-DRAM 등)],
  [셀(Tr+Cap)을 수평으로 눕혀 수십~수백 층 적층],
  [층수로 밀도 확보, 리소 부담 경감],
  [수평 커패시터 면적, 층간 균일도, 에피 Si/SiGe 적층 에치],
  [IGZO 채널],
  [산화물 반도체로 셀 Tr, off 누설 10⁻¹⁸ A/μm 이하],
  [retention 대폭 증가, 커패시터 축소 또는 2T0C],
  [이동도, V\_th 안정성, 열 예산],
  [2T0C 게인 셀],
  [쓰기 Tr + 읽기 Tr, 커패시터 없음],
  [HAR 커패시터 공정 제거],
  [retention 확보, 셀 면적],
  [HKMG 주변회로],
  [high-k/metal gate 주변 트랜지스터],
  [고속·저누설],
  [열 예산, 공정 스텝],
  [셀-주변 본딩],
  [어레이 웨이퍼와 주변 웨이퍼 하이브리드 본딩],
  [각자 최적 공정, 주변 면적],
  [본딩 정렬, 비용],
  [강유전체(FeRAM 계열)],
  [HfZrO 커패시터로 비휘발],
  [refresh 제거],
  [endurance, 분극 피로, 스케일링],
)

=== 3.10 NAND: floating gate vs charge trap

#table(
  columns: 3,
  align: left,
  table.header(
    [*항목*],
    [*Floating Gate(FG)*],
    [*Charge Trap(CTF)*],
  ),
  [저장층],
  [도체(poly-Si)],
  [절연체(SiN) 내부 트랩],
  [전하 분포],
  [FG 전체에 균일],
  [주입 위치 근처에 국소, 시간에 따라 측면 이동],
  [단일 결함 영향],
  [터널 산화막 한 점 결함으로 전하 전부 손실],
  [결함 근처 전하만 손실(내성 우수)],
  [셀 간 간섭],
  [FG-FG 커플링 커패시턴스 큼(2D 스케일링 한계)],
  [저장층 얇고 도체 아님 → 간섭 작음],
  [터널 산화막],
  [7~8 nm(두꺼워야 retention)],
  [4~6 nm 가능(밴드 엔지니어링 ONO 터널)],
  [스택 높이(3D)],
  [FG 두꺼워 층 피치 큼],
  [얇아 층 피치 축소 유리],
  [Erase 특성],
  [깊은 erase 용이],
  [erase 포화(블로킹 쪽 역주입) → high-k 블로킹(Al₂O₃) 필요],
  [Retention],
  [우수(도체에 전하 유지)],
  [초기 빠른 손실(shallow trap), 측면 확산],
  [3D 채택],
  [일부(Micron/Intel 초기 3D)],
  [주력(SK hynix, Samsung, Kioxia/WD)],
)

=== 3.11 2D → 3D 전환 이유

#table(
  columns: 3,
  align: left,
  table.header(
    [*2D 한계*],
    [*물리*],
    [*결과*],
  ),
  [셀 간 간섭],
  [FG-FG 커플링 비율이 피치 축소로 급증],
  [인접 셀 프로그램 시 V\_th 수백 mV 이동, TLC 불가],
  [전자 수 감소],
  [15 nm급 FG 저장 전자 수십 개],
  [전자 1개 손실이 수십 mV, RTN, retention tail],
  [터널 산화막],
  [7 nm 이하 못 줄임(retention) → 셀 종횡비 증가],
  [공정 난도, 패터닝 비용],
  [리소 비용],
  [1x nm 피치는 멀티 패터닝·EUV 필요],
  [비트당 비용 하락 정체],
  [Endurance],
  [얇은 산화막에 같은 전계 → 손상 가속],
  [P/E 사이클 1천 회 이하],
)

3D 전환의 논리: 평면 피치를 오히려 완화(수십~100 nm급 채널 홀)해 리소 비용을 줄이고, 층수로 밀도를 확보한다. 셀 면적이 커져 전자 수가 늘고 간섭이 줄어 TLC/QLC가 가능해졌다. 대신 HAR 채널 홀 에치, 층수만큼 두꺼운 스택의 균일 증착, 층별 특성 균일화라는 새 난제가 생겼다.

=== 3.12 3D NAND 구조 상세

```text
  3D NAND 단면(한 스트링, 개념도)              평면(채널 홀 배열, 슬릿)

  BL ------------------------------           |  o o o o o  |
   |                                          |  o o o o o  |  <- 채널 홀
  SSL (string select, 상단)  ====             |  o o o o o  |
  dummy WL                   ====            [슬릿(WLC): 블록/서브블록 분리]
  WL_n (W)  ====== ONO ======                 |  o o o o o  |
  ...              |채널|                     |  o o o o o  |
  WL_1 (W)  ====== poly ======
  dummy WL         |core|      <- macaroni core(SiO2) 안쪽,
  GSL (ground select, 하단) ==     poly-Si 채널이 관 형태
   |
  소스(CSL, n⁺ 또는 금속 플레이트)
  기판(또는 PUC 주변회로 위)

  게이트 스택(채널 홀 벽면, 바깥→안쪽):
   W WL | TiN | Al2O3(high-k 블로킹) | SiO2 블로킹 | SiN 트랩
        | 터널 산화막(ONO) | poly 채널 | SiO2 코어
```

#table(
  columns: 4,
  align: left,
  table.header(
    [*구성 요소*],
    [*재료/치수(대략)*],
    [*역할*],
    [*공정 이슈*],
  ),
  [채널 홀],
  [지름 60~120 nm(상부), aspect ratio 60~100 이상],
  [스트링 하나의 수직 통로],
  [HAR 에치 bowing·twisting, 상하 CD 차, 홀 위치 정확도],
  [몰드 스택],
  [SiO₂/SiN 교대(ONON) 수십~수백 쌍, 쌍 피치 40~60 nm],
  [WL(SiN→W 치환)과 층간 절연(SiO₂)],
  [층 두께 균일도, 응력, 웨이퍼 휨],
  [블로킹 산화막],
  [Al₂O₃ 수 nm + SiO₂ 수 nm],
  [게이트 쪽 전하 역주입 차단, erase 포화 방지],
  [Al₂O₃ 결정화·두께],
  [트랩층],
  [SiN 5~7 nm],
  [전하 저장],
  [트랩 밀도·조성(Si-rich), 측면 확산],
  [터널 산화막],
  [SiO₂ 또는 O/N/O 4~6 nm],
  [전하 주입·유지 장벽],
  [두께 상하 균일도, 결함],
  [채널],
  [poly-Si 5~10 nm 두께(macaroni)],
  [전류 경로, 소수 캐리어 없는 얇은 바디],
  [결정립 경계 트랩 → 이동도·V\_th 산포, 채널 저항],
  [코어],
  [SiO₂ 채움],
  [채널을 얇게 유지(SS 개선, 완전 공핍)],
  [보이드, 심(seam)],
  [WL],
  [W(또는 Mo), TiN 배리어],
  [게이트 겸 행 배선],
  [치환 공정 채움 보이드, 저항, F 잔류],
  [슬릿(WLC)],
  [스택 전체를 자르는 트렌치],
  [몰드 SiN 제거·W 증착 통로, 블록 분리, 소스 연결],
  [HAR 트렌치 에치, 채움, 정렬],
  [계단(staircase)],
  [WL 끝을 계단형으로 노출],
  [각 WL에 콘택],
  [트림-에치 반복 정확도, 면적 오버헤드],
  [SSL/GSL],
  [상·하단 선택 트랜지스터],
  [스트링 on/off, 서브블록 선택],
  [V\_th 균일도, 누설],
  [더미 WL],
  [선택 Tr 인접, 데크 접합부],
  [전계 완화, 데크 경계 셀 비사용],
  [용량 오버헤드],
  [소스],
  [n⁺ Si 또는 금속 플레이트(CSL)],
  [스트링 공통 소스, GIDL erase 시 정공 공급],
  [저항, 채널과의 접합],
)

단위 개념:

```text
 스트링(string) = 한 채널 홀의 직렬 셀들(SSL - 셀 × 단수 - GSL)
 페이지(page)   = 한 블록 안에서 같은 WL, 같은 SSL을 공유하는 셀들 → 동시 read/program
                  (TLC면 한 물리 페이지에 3개 논리 페이지: LSB/CSB/MSB)
 블록(block)    = 슬릿 사이 WL을 공유하는 모든 스트링 → erase 단위
 예: 200단 × 16 KB 페이지 × 4 스트링(SSL) × TLC 3 → 블록 약 38 MB
```

Multi-deck: 100단을 넘으면 한 번에 채널 홀을 에치하기 어려워 1차 스택(예: 100단) 채널 홀 → 2차 스택 증착 → 2차 채널 홀 순으로 나누고 데크 경계에서 홀을 정렬한다. 경계 정렬 오차와 채널 연결부 저항·결함이 생겨 경계 인접 WL은 더미로 쓴다. 300단급은 2~3 데크가 일반적이다.

=== 3.13 NAND 동작: FN 터널링, ISPP program, erase, read

FN(Fowler-Nordheim) 터널링: 산화막에 약 10 MV/cm(1 V/nm) 수준 전계를 걸면 전자가 삼각 장벽을 통과한다. 전류 밀도 J ∝ E²·exp(−B/E). 전계 10% 증가에 전류가 수 배~10배 늘어 매우 비선형이다.

Program(ISPP: incremental step pulse programming):

```text
 선택 WL: V_pgm 시작 약 14~16 V, 펄스 폭 약 10~20 μs, 매 스텝 +0.3~0.5 V 증가, 최대 20~24 V
 비선택 WL: V_pass 약 8~10 V (채널을 켜 프로그램 금지 스트링을 self-boosting)
 선택 BL: 0 V (프로그램) / V_cc (금지: 채널 부스팅으로 전계 감소)
 매 펄스 후 verify read → 목표 V_th 도달한 셀은 BL을 V_cc로 올려 금지

   V_th
    ^          목표 레벨 ---------------------
    |        /
    |      /   각 스텝마다 ΔV_th ≈ ΔV_pgm (약 0.3~0.5 V)
    |    /
    |  /
    +--------------------------------> 펄스 번호
 TLC 프로그램 총 시간 tPROG 약 300~600 μs, QLC 1~2 ms
```

ISPP를 쓰는 이유: 셀마다 터널 산화막 두께·채널 홀 CD가 달라 같은 전압에 다른 속도로 프로그램된다. 작은 스텝으로 올리며 verify하면 빠른 셀은 일찍 멈추고 느린 셀은 더 받아 최종 V\_th 분포 폭이 스텝 폭 수준으로 좁아진다. 스텝을 줄이면 분포는 좁아지지만 펄스 수가 늘어 tPROG가 길어진다.

Erase:

```text
 2D / 벌크 있는 구조: p웰(바디)에 +18~20 V, 모든 WL 0 V → 채널→트랩 방향 전계로 전자 방출·정공 주입
 3D CTF(poly 채널, 벌크 없음): GIDL erase
   - 소스(CSL)와 BL에 높은 전압(약 15~20 V), GSL/SSL 게이트는 그보다 몇 V 낮게
   - 선택 Tr의 게이트-드레인 오버랩에서 GIDL로 정공 생성 → 채널로 주입 → 채널 전위 상승
   - WL 0 V이므로 트랩층에서 전자가 채널로 빠지고 정공이 주입됨
   - 블록 단위, tBERS 약 2~5 ms, erase verify 후 필요 시 재펄스
```

3D NAND에서 GIDL은 erase의 필수 도구다(DRAM에서는 적, NAND에서는 도구). GSL/SSL의 접합 프로파일과 오버랩이 erase 속도를 결정하며, GIDL이 부족하면 erase가 느리거나 블록 일부가 덜 지워진다.

Read:

```text
 선택 WL: V_read (판별 레벨, 예: TLC 7개 레벨 중 하나, 대략 0~5 V)
 비선택 WL: V_pass 약 6~8 V (모든 비선택 셀을 켜서 스트링을 도통시킴)
 SSL/GSL: on, 소스 0 V, BL 프리차지 약 0.5~1 V
 셀 V_th < V_read → 스트링 전류 흐름(수십~수백 nA) → BL 방전 → "1"(erased 쪽)
 셀 V_th > V_read → 전류 없음 → "0"
 tR: SLC 약 20~30 μs, TLC 약 50~90 μs, QLC 100 μs 이상(레벨 수와 센싱 반복)
```

V\_pass는 두 조건 사이에 있어야 한다: 가장 높은 프로그램 상태 V\_th보다 충분히 높아 도통시키되(마진 부족 시 read 전류 감소 → 오판), 너무 높으면 비선택 셀에 약한 프로그램(read disturb)이 일어난다.

=== 3.14 SLC/MLC/TLC/QLC의 V\_th 분포와 read margin

```text
 V_th 창(대략 −3 V ~ +5 V, 약 7~8 V)

 SLC:   [ E ]                      [ P ]           레벨 1개, 마진 수 V
 MLC:   [ E ]   [P1]    [P2]    [P3]               레벨 3개
 TLC:   [E][P1][P2][P3][P4][P5][P6][P7]            레벨 7개, 폭 ~0.5 V, 간격 0.3~0.5 V
 QLC:   [E][1][2][3][4][5][6][7][8][9][A][B][C][D][E][F]   레벨 15개, 간격 0.2~0.3 V

 read margin = 인접 상태 분포 사이 빈 공간. 분포가 넓어지거나(σ↑) 이동하면(shift) 겹침 → bit error
```

#table(
  columns: 5,
  align: left,
  table.header(
    [*항목*],
    [*SLC*],
    [*MLC*],
    [*TLC*],
    [*QLC*],
  ),
  [상태 수 / read 레벨],
  [2 / 1],
  [4 / 3],
  [8 / 7],
  [16 / 15],
  [상태당 허용 폭(대략)],
  [수 V],
  [약 1 V],
  [약 0.5 V],
  [약 0.3 V],
  [tPROG(대략)],
  [100~200 μs],
  [300~600 μs],
  [500 μs~1 ms],
  [1~3 ms],
  [tR(대략)],
  [20~30 μs],
  [40~60 μs],
  [50~90 μs],
  [100~200 μs],
  [P/E 사이클(대략)],
  [5만~10만],
  [1만],
  [1천~5천],
  [1천 안팎],
  [요구 ECC],
  [BCH 수준],
  [BCH/LDPC],
  [LDPC 필수],
  [강력 LDPC + soft read],
  [용도],
  [캐시, 산업용],
  [구형 SSD],
  [주력 SSD·모바일],
  [대용량·읽기 중심],
)

V\_th 분포가 넓어지는 원인: 터널 산화막·홀 CD 산포(프로그램 속도 차), RTN, 프로그램 노이즈(전자 개수 요동), 셀 간 커플링(CTF는 작지만 존재), 층 위치(상·하부 홀 CD 차로 전계 다름). 분포가 이동하는 원인: retention(전하 손실로 하향), disturb(상향), 온도(읽기 시점 온도와 프로그램 시점 온도 차 → cross-temperature 오류).

#callout("예시")[TLC에서 P7 상태 평균 4.5 V, σ 0.15 V, P6 평균 3.8 V, σ 0.15 V, read 레벨 4.15 V. P6 분포에서 read 레벨을 넘는 비율은 (4.15 − 3.8)/0.15 = 2.33σ → 약 1%로, RBER로는 너무 크다. 실제로는 σ를 0.1 V 이하로 관리해 3.5σ(2×10⁻⁴) 수준을 만들고, LDPC가 10⁻²~10⁻³ RBER까지 정정하므로 초기 마진을 retention·disturb·cycling 후에도 확보하도록 설계한다. σ가 0.02 V 늘어나는 것이 RBER 10배 차이가 될 수 있다.]

=== 3.15 Disturb 3종

#table(
  columns: 5,
  align: left,
  table.header(
    [*종류*],
    [*언제*],
    [*피해 셀*],
    [*기구*],
    [*대책*],
  ),
  [Program disturb],
  [선택 WL 프로그램 중],
  [같은 WL, 프로그램 금지 스트링의 셀],
  [금지 스트링 채널 부스팅 전위가 누설로 떨어져 게이트-채널 전계 증가 → 약한 FN 주입],
  [부스팅 효율 향상(local self-boosting), 채널 누설 억제(GSL/SSL off 누설, 접합), 더미 WL],
  [Pass disturb],
  [다른 WL 프로그램 중],
  [선택 스트링(BL 0 V)의 비선택 WL 셀],
  [V\_pass(8~10 V)가 채널 0 V인 셀에 반복 인가 → 약한 주입],
  [V\_pass 최적화(program disturb와 trade-off), 프로그램 순서],
  [Read disturb],
  [읽기 반복],
  [같은 블록 비선택 WL 셀],
  [V\_pass(6~8 V) 반복 → erased 셀 V\_th 상승],
  [읽기 카운트 기반 블록 refresh(re-write), V\_pass 최소화, 레벨 조정],
)

Program disturb와 pass disturb는 V\_pass 선택에서 정면 충돌한다. V\_pass를 올리면 부스팅이 좋아져 program disturb가 줄지만 pass disturb가 늘고, 내리면 반대다. 최적 V\_pass 창이 좁아지는 것이 고단화·QLC의 어려움 중 하나다.

#callout("면접")["NAND에서 disturb란 무엇이고 왜 생깁니까?" → 결론: 선택하지 않은 셀이 program이나 read 동작 중 받는 전압 때문에 V\_th가 의도치 않게 변하는 현상입니다. 근거: NAND는 한 WL에 수만 개 셀, 한 스트링에 수백 개 셀이 물려 있어 한 셀을 프로그램하려면 같은 WL의 다른 셀에도 20 V 가까운 전압이, 같은 스트링의 다른 셀에도 8~10 V의 pass 전압이 걸리며, FN 터널링은 전계에 지수적이라 이 전압만으로도 약한 주입이 누적됩니다. 예시: 금지 스트링의 채널 부스팅이 GSL 누설로 빠지면 program disturb, 10만 회 읽기 후 erased 셀 V\_th가 올라가면 read disturb이며, PE는 프로그램 직후와 반복 읽기 후 분포를 따로 측정해 둘을 분리하고 GSL/SSL 누설·V\_pass 최적화로 대응합니다.]

=== 3.16 Retention과 endurance 메커니즘

Retention(전하 손실):

#table(
  columns: 3,
  align: left,
  table.header(
    [*기구*],
    [*설명*],
    [*특징*],
  ),
  [얕은 트랩 탈출(detrapping)],
  [얕은 에너지 트랩의 전자가 열적으로 방출],
  [프로그램 직후 수 시간~수 일 빠른 초기 손실],
  [터널 산화막 통한 누설],
  [전자가 채널로 직접·트랩 매개 터널링],
  [산화막 얇거나 cycling 손상 시 급증(SILC)],
  [측면 전하 확산(lateral migration)],
  [CTF 트랩층 안에서 전하가 WL 사이 공간으로 퍼짐],
  [3D CTF 고유, 고온에서 가속, 셀 V\_th 하향],
  [블로킹 쪽 손실],
  [전자가 게이트로 빠짐],
  [high-k 블로킹 품질, 고온],
  [정공 재결합],
  [erase 시 주입된 정공과 재결합],
  [erased 상태 V\_th 상승],
)

Retention 규격은 대략 소비자용 1년(40°C 저장), 기업용 3개월(40°C) 수준이며, Arrhenius 가속(E\_a 약 1.1 eV 사용 관례)으로 고온 베이크 테스트를 한다. 예: 85°C 수 시간~수십 시간이 40°C 1년에 해당하는 식으로 환산한다.

Endurance(P/E cycling 열화):

```text
 P/E 반복 → 터널 산화막·계면에 트랩 생성(고전계 스트레스, 정공 주입)
   → (1) 트랩 전하가 V_th를 이동(erased 상태 상승, 창 축소)
   → (2) 트랩이 SILC 경로 → retention 악화
   → (3) 프로그램 속도 변화(빨라지다가 느려짐) → 분포 폭 증가
   → (4) RTN 증가
 결과: cycling 후 read margin 감소 → RBER 증가 → ECC 한계 → 블록 폐기(bad block)
```

수명 관리: 웨어 레벨링(블록 간 균등 사용), 배드 블록 관리, cycling에 따른 read 레벨 보정, 고온에서 프로그램(트랩 어닐링 효과)과 같은 시스템·펌웨어 기법이 물리 한계를 보완한다.

=== 3.17 ECC와 read retry

#table(
  columns: 3,
  align: left,
  table.header(
    [*기법*],
    [*내용*],
    [*효과*],
  ),
  [BCH],
  [대수적 하드 디시전 코드, 수십 비트/KB 정정],
  [MLC까지 주력],
  [LDPC],
  [반복 복호, soft 정보 활용, RBER 10⁻²급 정정],
  [TLC/QLC 필수, 지연·전력 증가],
  [Read retry],
  [실패 시 read 레벨을 이동해 재읽기(retention 하향·disturb 상향 보정)],
  [분포 이동 대응],
  [Soft-decision read],
  [레벨 주변 여러 번 읽어 신뢰도(LLR) 생성 → LDPC에 입력],
  [정정 능력 대폭 향상, tR 증가],
  [온도 보상],
  [프로그램/읽기 온도 차 보정],
  [cross-temperature 오류 감소],
  [On-die ECC(DRAM DDR5)],
  [128+8 비트 SEC],
  [retention 산발 fail·VRT 구제],
  [Refresh/재기록(NAND)],
  [read count·경과 시간 기반 블록 재기록],
  [read disturb·retention 누적 해소],
)

PE 관점: ECC는 tail을 "허용"하는 도구이지만 원인을 없애지는 않는다. ECC 정정 횟수·read retry 빈도가 늘어나는 것 자체가 공정 열화의 조기 신호이므로 수율·신뢰성 지표로 모니터한다.

=== 3.18 PUC/CoP, 웨이퍼 본딩, multi-deck 구조 차이

#table(
  columns: 4,
  align: left,
  table.header(
    [*구조*],
    [*설명*],
    [*장점*],
    [*단점/과제*],
  ),
  [주변 옆 배치(초기 3D)],
  [셀 어레이 옆에 주변회로],
  [단순],
  [다이 면적 오버헤드 20~30%],
  [PUC / CoP / CuA],
  [주변회로를 먼저 만들고 그 위에 셀 어레이 적층(SK hynix 4D NAND = PUC + CTF, Samsung CoP, Micron CuA)],
  [면적 효율, 비트 밀도],
  [주변 Tr이 어레이 열공정(수백~1000°C 근접)을 견뎌야 함 → 주변 성능 제약, 어레이 아래 배선],
  [웨이퍼 본딩(CBA, Xtacking)],
  [어레이 웨이퍼와 CMOS 웨이퍼를 따로 만들어 하이브리드 본딩],
  [주변 CMOS를 로직급 공정으로(고속 I/O), 열 예산 분리, 병렬 제조],
  [본딩 정렬(수백 nm), 본딩 패드 밀도, 비용, 두 웨이퍼 수율 곱],
  [Multi-deck],
  [스택을 2~3 데크로 나눠 채널 홀 에치],
  [300단 이상 가능],
  [데크 경계 정렬·연결 저항, 더미 WL 오버헤드, 공정 스텝 증가],
)

=== 3.19 핵심 공정 변수 표(개요)

#table(
  columns: 4,
  align: left,
  table.header(
    [*변수*],
    [*조절 방향*],
    [*영향 받는 결과*],
    [*모니터링 항목/계측*],
  ),
  [(DRAM) BCAT 리세스 깊이],
  [에치 시간·종점],
  [유효 L → V\_th, I\_off, DIBL, retention],
  [단면 SEM/TEM, 전기적 V\_th 맵],
  [(DRAM) WL 일함수/오버랩],
  [poly/W 높이 비, 스페이서],
  [GIDL, V\_th],
  [GIDL 전류, retention E\_a],
  [(DRAM) 커패시터 높이·CD],
  [HAR 에치, 몰드 두께],
  [C\_s → 센싱 마진, retention],
  [커패시터 C-V, TEM, OCD],
  [(DRAM) ZAZ 두께·결정성],
  [ALD 사이클, 어닐],
  [C\_s, 커패시터 누설],
  [C-V, I-V, XRD],
  [(DRAM) SNC/BLC 콘택 저항],
  [pre-clean, 채움],
  [tWR, tRCD],
  [콘택 체인, TLM],
  [(DRAM) BL/WL 저항],
  [금속 두께·CMP],
  [tRCD, tRP, 노이즈],
  [사행선 저항],
  [(NAND) 채널 홀 CD·프로파일],
  [HAR 에치 조건],
  [층별 V\_th·프로그램 속도 차, 분포 폭],
  [상·하부 CD(SEM 단면, OCD), 층별 V\_th],
  [(NAND) ONO 각 층 두께],
  [ALD/CVD 사이클],
  [program/erase 속도, retention, erase 포화],
  [TEM, 전기적 프로그램 속도],
  [(NAND) poly 채널 두께·결정립],
  [증착·어닐],
  [스트링 전류, SS, V\_th 산포],
  [스트링 I-V, TEM],
  [(NAND) W WL 채움·저항],
  [치환 공정],
  [WL RC → tR, 층별 타이밍],
  [WL 저항, 단면 보이드 검사],
  [(NAND) 슬릿·계단 정렬],
  [리소 오버레이],
  [블록 분리 불량, WL 콘택 오픈/쇼트],
  [오버레이 계측, 전기 테스트],
  [(NAND) 데크 정렬],
  [2차 홀 오버레이],
  [경계 저항, 경계 셀 특성],
  [오버레이, 경계 WL 특성],
)

=== 3.20 DRAM vs NAND 종합 비교표

#table(
  columns: 3,
  align: left,
  table.header(
    [*항목*],
    [*DRAM*],
    [*NAND*],
  ),
  [셀 구조],
  [1T1C(BCAT + 원통 커패시터)],
  [1T(CTF 셀), 수직 스트링 직렬],
  [저장 원리],
  [커패시터 전하 유무],
  [트랩층 전하량 → V\_th 변조],
  [휘발성],
  [휘발성, refresh 64 ms(85°C)],
  [비휘발성, 수 년 retention],
  [트랜지스터 종류],
  [매립 채널 Si NMOS(단결정), 주변은 planar/HKMG],
  [poly-Si 채널 GAA형 macaroni, 얇은 바디],
  [셀 크기/밀도],
  [6F², 다이 16~32 Gb],
  [층당 면적은 크지만 200~300단 적층, 다이 1~2 Tb],
  [셀당 비트],
  [1],
  [1(SLC)~4(QLC)],
  [접근 시간],
  [read/write 수십 ns 랜덤],
  [read 수십 μs, program 수백 μs~ms, erase ms],
  [쓰기 전압],
  [1~3 V(V\_PP)],
  [15~24 V(FN 터널링)],
  [Endurance],
  [사실상 무한],
  [1천~10만 P/E],
  [핵심 공정 모듈],
  [BCAT 리세스 에치, HAR 커패시터 에치, ALD ZAZ, 매립 W WL, 콘택],
  [수백 층 ONON 증착, HAR 채널 홀 에치, ONO ALD, poly 채널, 치환 게이트 W, 계단 에치],
  [공정 난이도 포인트],
  [커패시터 aspect ratio 50~100·쓰러짐, 셀 Tr 누설 극소화, 열 예산],
  [홀 aspect ratio 60~100 이상·상하 CD 균일, 층별 균일도, 응력·휨, 데크 정렬],
  [대표 불량],
  [retention tail, VRT, tWR/tRCD fail, row hammer, 커패시터 누설·쇼트],
  [V\_th 분포 확대, program/erase fail, disturb, retention 손실, 배드 블록, WL 쇼트/오픈],
  [핵심 특성 파라미터],
  [C\_s, 셀 V\_th·I\_off, GIDL, tRCD/tWR/tRFC, refresh 전력],
  [V\_th 창·분포 σ, tPROG/tR/tBERS, P/E cycle, RBER, disturb 마진],
  [테스트 관점],
  [웨이퍼 테스트에서 retention·타이밍 스크린, 리던던시 repair, 번인],
  [초기 V\_th 분포, 배드 블록 판정, ECC 여유, cycling·베이크 신뢰성],
  [오류 구제],
  [리던던시 row/col + on-die ECC(DDR5)],
  [강력 LDPC + read retry + 배드 블록 + 웨어 레벨링],
  [스케일링 방향],
  [4F² VCT, 3D DRAM 적층, IGZO, HBM 적층],
  [단수 증가(300→500단 이상), 층 피치 축소, 셀당 비트 증가, 웨이퍼 본딩],
  [대표 제품],
  [DDR5, LPDDR5X, GDDR7, HBM3E/4],
  [TLC/QLC SSD, UFS, eMMC, 엔터프라이즈 SSD],
)

#callout("면접")["DRAM과 NAND의 차이를 1분 안에 설명하세요." → 결론: DRAM은 커패시터에 전하를 저장하는 휘발성 고속 메모리이고, NAND는 트랩층 전하로 트랜지스터 문턱전압을 바꾸는 비휘발성 고밀도 메모리입니다. 근거: DRAM은 1T1C 셀을 수십 ns에 읽고 쓰지만 누설 때문에 64 ms마다 refresh가 필요하고 셀당 1비트입니다. NAND는 FN 터널링으로 20 V 가까운 전압을 걸어 수백 μs에 프로그램하며 수 년 유지하지만 산화막이 상해 수천 회 P/E 제한이 있고, 셀당 3~4비트와 200~300단 적층으로 밀도를 얻습니다. 예시: 공정에서도 DRAM 난제는 aspect ratio 50~100의 커패시터와 셀 트랜지스터 누설이고, NAND 난제는 수백 층을 관통하는 채널 홀 에치와 층별 균일도입니다. 그래서 PE가 보는 대표 불량도 DRAM은 retention tail, NAND는 V\_th 분포 확대로 갈립니다.]

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 4. 결함·불량 유형

=== 4.1 DRAM

#table(
  columns: 5,
  align: left,
  table.header(
    [*결함명*],
    [*현상*],
    [*발생 원인*],
    [*검출/분석 방법*],
    [*대책*],
  ),
  [Retention tail(단일 셀)],
  [특정 셀 64 ms 미만, 고온 악화],
  [접합 결함·오염(SRH), GIDL 큰 셀, 커패시터 누설],
  [retention 맵, 온도 E\_a, V\_WL(off) 의존],
  [오염 관리, 오버랩 최적화, ECC/repair],
  [VRT],
  [셀 retention이 시간에 따라 두 값 사이 전환],
  [공핍층 단일 트랩의 전하 상태 요동],
  [반복 retention 측정, 상태 전환 통계],
  [스트레스 스크린, ECC, 마진 refresh],
  [Row hammer 취약],
  [인접 행 반복 ACT 후 victim fail],
  [WL 커플링, 캐리어 주입, 격리 약화],
  [hammer 테스트(횟수 vs fail)],
  [TRR/RFM/PRAC, 격리·프로파일 개선],
  [tWR fail],
  [쓰기 후 데이터 미완성],
  [SNC/BLC R\_c 증가, 셀 Tr V\_th 높음, 전극 저항],
  [tWR 마진 테스트, 콘택 체인, V\_th 맵],
  [pre-clean, 리세스 깊이, TiN 두께],
  [tRCD fail(행 위치 의존)],
  [드라이버 먼 쪽 행 느림],
  [WL W 채움 보이드, WL CD 축소],
  [행 위치별 fail 분포, WL 저항 패턴, 단면],
  [W 증착·에치백 조건],
  [센싱 fail / C\_s 저하],
  [특정 영역 랜덤 fail, 마진 테스트 민감],
  [커패시터 높이 손실, 유전체 두꺼움, 서포터 면적],
  [커패시터 C-V, TEM, OCD],
  [HAR 에치·ALD 조건],
  [커패시터 쇼트(브리지)],
  [인접 셀 쌍 fail, BL 쇼트],
  [기둥 쓰러짐(leaning), 몰드 잔류, 플레이트 침투],
  [페어 fail 패턴, SEM top-view],
  [서포터 설계, 습식 제거 조건],
  [커패시터 누설],
  [고전압·고온 retention 저하],
  [ZAZ 결함, Al₂O₃ 결손, TiN 거칠기],
  [커패시터 I-V 온도·전압, TEM],
  [ALD 균일도, 전극 표면],
  [BL 쇼트/오픈],
  [컬럼 단위 fail],
  [패터닝 브리지, 보이드],
  [컬럼 fail 맵, 전압 대비 검사(VC-SEM)],
  [리소·에치 마진],
  [WL 쇼트/오픈],
  [행 단위 fail],
  [매립 WL 보이드, 인접 WL 브리지],
  [행 fail 맵, 단면],
  [트렌치 채움·에치백],
  [셀 Tr V\_th 산포],
  [repair 초과, retention·tWR 양쪽 tail],
  [리세스 깊이·CD 산포, 일함수 산포],
  [V\_th 맵(테스트 패턴), 단면],
  [에치 균일도, 게이트 스택],
  [주변 대기 전류 fail(IDD)],
  [저전력 규격 초과],
  [주변 Tr 게이트·접합 누설, 고전압 Tr 누설],
  [IDD 측정, 블록별 전류 분리],
  [게이트 산화막·접합 관리],
  [I/O 고속 fail],
  [고속 MT/s에서 에러],
  [드라이버 I\_on 저하, 지터, 배선 RC],
  [아이 다이어그램, 슈무 플롯],
  [주변 Tr 성능, 배선],
  [데이터 패턴 의존 fail],
  [특정 체커보드 등 패턴에서만 fail],
  [BL/셀 커플링, 인접 셀 disturb],
  [패턴별 테스트],
  [격리·커플링 저감],
)

=== 4.2 NAND

#table(
  columns: 5,
  align: left,
  table.header(
    [*결함명*],
    [*현상*],
    [*발생 원인*],
    [*검출/분석 방법*],
    [*대책*],
  ),
  [V\_th 분포 확대(초기)],
  [프로그램 후 σ 큼, RBER 초기 높음],
  [채널 홀 CD·ONO 두께 산포, poly 결정립, RTN],
  [층별·블록별 V\_th 분포, 홀 CD 계측],
  [HAR 에치·ALD 균일도, ISPP 스텝],
  [층별 V\_th shift],
  [상부/하부 WL 셀 특성 계통 차이],
  [홀 상하 CD 차(테이퍼), 전계 집중],
  [층 위치 vs V\_th·프로그램 속도],
  [층별 V\_pgm 보정, 에치 프로파일],
  [Program fail(느린 셀)],
  [최대 펄스에도 목표 미달],
  [터널 산화막 두꺼움, 홀 큼(전계 약), 채널 저항 큼],
  [프로그램 펄스 수 분포, 위치],
  [ONO 두께, 홀 CD, 채널],
  [Erase fail / 얕은 erase],
  [블록 erase 후 V\_th 높음],
  [GIDL 부족(GSL/SSL 프로파일), 블로킹 역주입(포화), 트랩],
  [erase 펄스 수, erase 후 분포],
  [선택 Tr 접합, Al₂O₃ 두께],
  [Program disturb],
  [금지 셀 V\_th 상승],
  [채널 부스팅 누설(GSL/SSL 누설, 접합), V\_pass 낮음],
  [disturb 테스트(패턴), 부스팅 전위 추정],
  [선택 Tr 누설 개선, V\_pass, 더미 WL],
  [Read disturb],
  [다수 읽기 후 erased 셀 상승],
  [V\_pass 반복 FN 약주입],
  [읽기 횟수 vs RBER],
  [V\_pass 최소화, 블록 refresh],
  [Retention 손실],
  [베이크 후 V\_th 하향, 특히 상위 상태],
  [얕은 트랩, 측면 확산, SILC(cycling 후)],
  [베이크 전후 분포 shift, E\_a],
  [트랩층 조성, 터널 산화막 품질],
  [Endurance 부족],
  [목표 P/E 이전 RBER 초과],
  [터널 산화막 트랩 생성 가속, 정공 손상],
  [cycling vs RBER 곡선],
  [산화막 질화·두께, 전계 저감(ISPP 최적)],
  [WL 쇼트(인접 층)],
  [두 WL 사이 누설, 블록 fail],
  [몰드 SiO₂ 얇음·핀홀, W 치환 시 잔류],
  [WL 간 누설 테스트, 단면],
  [몰드 두께·치환 세정],
  [WL 오픈/저항],
  [특정 WL 느림·읽기 실패],
  [W 채움 보이드, 계단 콘택 미착],
  [WL 저항, 계단 콘택 검사],
  [치환 채움, 계단 에치 정밀도],
  [채널 홀 미개통(not-open)],
  [스트링 전체 fail],
  [HAR 에치 정지, 잔막],
  [스트링 전류 0, 단면],
  [에치 종점·오버에치 마진],
  [홀 bowing/twisting],
  [인접 홀 접촉 → 쇼트, 층별 특성 이상],
  [에치 프로파일 제어 실패],
  [top/단면 SEM, 인접 스트링 쇼트],
  [에치 가스·바이어스 튜닝],
  [채널 저항 큼],
  [스트링 전류 낮아 read 오판],
  [poly 두께·결정립, 데크 경계 연결 불량],
  [스트링 I-V],
  [poly 증착·어닐, 데크 정렬],
  [슬릿 리크],
  [블록 간 간섭, 소스 저항],
  [슬릿 채움 불량, 정렬],
  [블록 간 누설],
  [슬릿 공정],
  [배드 블록 과다],
  [초기 불량 블록 비율 규격 초과],
  [위 결함들의 집합],
  [초기 테스트],
  [근본 원인 모듈별 개선],
)

#callout("핵심")[DRAM 불량은 "시간(retention)과 타이밍(tRCD/tWR)"으로, NAND 불량은 "분포(V\_th σ와 shift)와 수명(cycling)"으로 나타난다. 같은 "누설"이라도 DRAM에서는 fA 단위 셀 누설이, NAND에서는 수십 년 시간 축의 전하 손실이 문제라는 점에서 분석 방법이 완전히 다르다.]

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 5. 공정 변수 ↔ 소자/제품 특성 상관관계

이 절은 개요다. 모듈별 상세(에치·증착·리소·주입·CMP·세정 각각의 변수와 특성 연결)는 13장(DRAM 공정-특성 상관)과 14장(NAND 공정-특성 상관)에서 다룬다.

=== 5.1 DRAM: 공정 변수가 흔들리면

#table(
  columns: 4,
  align: left,
  table.header(
    [*공정 변수 shift*],
    [*소자 파라미터 변화*],
    [*특성 불량*],
    [*수율/신뢰성*],
  ),
  [BCAT 리세스 얕음],
  [유효 L↓ → V\_th↓, DIBL↑],
  [I\_off↑ → retention tail, 고온 refresh fail],
  [repair 증가, 고온 수율],
  [BCAT 리세스 깊음],
  [V\_th↑, I\_on↓],
  [tWR·tRCD 저온 fail],
  [저온 수율],
  [WL W 리세스(에치백) 얕음 → 오버랩 증가],
  [GIDL↑],
  [retention tail(음 WL 의존)],
  [고온·저 V\_WL 조건 fail],
  [WL 폭(CD) 축소],
  [WL 저항↑],
  [tRCD·tRP 행 위치 의존 fail],
  [고속 bin 하락],
  [커패시터 홀 CD 축소·높이 손실],
  [C\_s↓],
  [센싱 마진↓, retention↓],
  [마진 테스트 fail, 노이즈 취약],
  [ZAZ 두께 증가],
  [C\_s↓],
  [위와 동일],
  [-],
  [ZAZ 두께 감소·Al₂O₃ 결손],
  [커패시터 누설↑],
  [retention tail, 고전압 취약],
  [신뢰성(TDDB)],
  [커패시터 기둥 쓰러짐],
  [인접 SN 쇼트],
  [페어 셀 fail],
  [리던던시 소모],
  [SNC pre-clean 불량],
  [R\_c↑],
  [tWR fail],
  [특정 로트 수율],
  [셀 접합 주입 과다·어닐 부족],
  [접합 누설↑, 결함 잔류],
  [고온 retention tail(E\_a 0.55)],
  [고온 수율, VRT],
  [금속 오염],
  [τ\_g↓ → 접합 누설↑],
  [무작위 retention tail],
  [로트 단위 수율 급락],
  [주변 게이트 산화막 얇음],
  [게이트 누설↑, V\_th↓],
  [IDD 대기 전류 fail],
  [저전력 제품 등급 하락],
  [BL 커패시턴스 증가(층간막 얇음)],
  [C\_BL↑ → ΔV↓],
  [센싱 fail],
  [마진],
)

=== 5.2 NAND: 공정 변수가 흔들리면

#table(
  columns: 4,
  align: left,
  table.header(
    [*공정 변수 shift*],
    [*소자 파라미터 변화*],
    [*특성 불량*],
    [*수율/신뢰성*],
  ),
  [채널 홀 상하 CD 차 증가],
  [층별 전계 차 → 층별 V\_th·프로그램 속도 차],
  [층별 분포 shift, ISPP 펄스 증가],
  [tPROG↑, RBER↑],
  [채널 홀 bowing],
  [인접 홀 접근·ONO 두께 불균일],
  [스트링 쇼트, 국부 V\_th 이상],
  [블록 fail],
  [터널 산화막 얇음],
  [FN 전류↑],
  [program 빠름, retention↓, endurance↓],
  [신뢰성 fail],
  [터널 산화막 두꺼움],
  [FN 전류↓],
  [program·erase 느림, disturb 마진↓],
  [성능 bin 하락],
  [트랩층 두께·조성 변동],
  [트랩 밀도·깊이 변화],
  [V\_th 창 변화, retention 초기 손실],
  [분포 shift],
  [블로킹 Al₂O₃ 얇음],
  [게이트 역주입↑],
  [erase 포화, program 효율↓],
  [erase fail],
  [poly 채널 두꺼움·결정립 작음],
  [스트링 전류↓, SS↑],
  [read 오판, 상위 층 느림],
  [RBER, tR],
  [W WL 보이드],
  [WL 저항↑],
  [층별 타이밍 편차, WL 상승 지연],
  [tR↑, 특정 WL fail],
  [몰드 SiO₂ 얇음],
  [WL 간 절연↓],
  [WL-WL 쇼트],
  [블록 fail],
  [GSL/SSL 접합 프로파일 변동],
  [GIDL erase 효율, 선택 Tr 누설 변화],
  [erase 느림, program disturb↑],
  [erase fail, disturb fail],
  [슬릿/계단 오버레이 오차],
  [WL 콘택 미착·쇼트, 블록 분리 불량],
  [WL 오픈, 블록 간 간섭],
  [블록 fail],
  [데크 경계 정렬 오차],
  [연결부 저항↑, 경계 셀 이상],
  [스트링 전류↓, 경계 WL fail],
  [더미 WL 확대 필요],
  [스택 응력·웨이퍼 휨],
  [오버레이 악화, 홀 기울어짐],
  [위 항목들의 복합],
  [로트 수율],
)

=== 5.3 두 제품의 "민감도 지도"

```text
 DRAM: 셀 Tr 누설(fA) ← 리세스 깊이, 일함수, 오버랩, 오염
       C_s(fF)         ← 홀 CD, 높이, ZAZ 두께·κ
       R(Ω)            ← 콘택 pre-clean, WL/BL 채움
       → retention, tWR, tRCD 로 나타남

 NAND: V_th 분포(V)   ← 홀 CD 프로파일, ONO 두께, poly 결정성
       FN 전계(MV/cm) ← 터널 산화막 두께, 홀 CD(곡률)
       WL RC           ← W 채움, 층 피치
       → tPROG/tR, RBER, disturb 마진, endurance 로 나타남
```

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 6. 트러블슈팅 케이스

=== 케이스 1: DRAM 특정 WL 위치의 tRCD fail

- 증상: 신제품 고속 bin(6400 MT/s) 수율 저하. tRCD 마진 테스트에서 fail 행이 각 서브어레이의 SWD에서 먼 쪽 절반에 집중.
- 1차 데이터: fail 맵이 다이 내 모든 서브어레이에서 동일 패턴(드라이버 원거리 쪽). 웨이퍼 맵은 중심보다 에지에서 심함. retention·tWR은 정상. WL 저항 테스트 패턴(사행선)이 에지에서 25% 높음.
- 가설 나열: (a) 매립 WL W 채움 보이드(에지), (b) WL 트렌치 CD 에지 축소, (c) TiN 배리어 에지 두꺼움(W 단면 잠식), (d) SWD 구동력 저하(주변 Tr).
- 가설 검증: (d)는 fail이 원거리 쪽에만 있고 근거리 정상이므로 WL RC 문제 → 기각. 단면 TEM 에지 다이 → W 내부 심(seam)·보이드 확인, CD 정상 → (b) 기각. TiN 두께 에지/중심 동일 → (c) 기각. W CVD 핵생성층 에지 두께 편차와 트렌치 상부 넥(neck) 형상이 보이드 유발.
- 근본 원인: 트렌치 상부 좁아짐(리세스 에치 프로파일) + W 핵생성층 에지 두꺼움 → 조기 폐색 → 보이드 → WL 저항 증가 → 원거리 셀 WL 상승 지연 → tRCD 초과.
- 조치: W 핵생성층 두께 축소·증착 균일도 개선, 리세스 에치 프로파일 상부 각도 조정. 영향 로트는 저속 bin 판정.
- 재발 방지: WL 사행선 저항 에지/중심 비율을 인라인 SPC로, 단면 보이드 검사 주기 설정.

=== 케이스 2: DRAM 고온 retention tail이 음 WL 전압에 민감

- 증상: 85°C retention tail 셀 수가 목표의 3배. V\_WL(off)을 −0.3 V에서 −0.15 V로 올리면 tail이 절반으로 줄지만 subthreshold 누설 셀이 늘어남.
- 1차 데이터: tail 셀 온도 E\_a 약 0.25 eV(GIDL/TAT 영역). 다이 내 위치 무작위. 웨이퍼 간 재현. GIDL 테스트 패턴 전류 이전 세대 대비 2배.
- 가설 나열: (a) WL 에치백이 얕아 W 상단이 접합과 오버랩, (b) 이중 일함수 poly 높이 부족, (c) 접합 프로파일 급경사(도즈·어닐), (d) 오버랩 영역 계면 트랩(TAT).
- 가설 검증: 단면 TEM에서 W 상단 높이 목표 대비 +8 nm(에치백 부족) 확인, poly 높이는 그만큼 감소 → (a)(b) 동시. SIMS 접합 프로파일은 정상 → (c) 기각. E\_a 0.25로 TAT 성분 일부 존재 가능 → (d) 보조 요인.
- 근본 원인: W 에치백 종점 편차 → 금속 게이트가 접합 근처까지 올라와 고일함수 금속-접합 오버랩 전계 증가 → GIDL 증가.
- 조치: 에치백 시간·종점 재설정, poly 채움 높이 확보. V\_WL(off) 임시 −0.2 V로 조정해 tail 완화.
- 재발 방지: W 에치백 후 리세스 깊이 OCD 인라인 계측 추가, GIDL 테스트 패턴을 로트 릴리스 항목에 포함.

#callout("아이디어")[GIDL과 subthreshold 누설의 최적 V\_WL(off)이 셀마다 다르므로 다이 전체에 하나의 값을 쓰면 어느 쪽 tail이든 남는다. 서브어레이 단위로 V\_WL(off)을 미세 조정(트리밍)하거나, 테스트에서 tail 셀 종류(E\_a)를 분류해 GIDL형은 리던던시로, subthreshold형은 전압 트리밍으로 나눠 구제하는 방식이 가능하다.]

=== 케이스 3: 3D NAND 상부 데크 특정 층 프로그램 느림

- 증상: TLC 프로그램 시 상부 데크 하단 10개 WL(데크 경계 위쪽)에서 ISPP 펄스 수 평균 +4, tPROG 15% 증가, 해당 층 V\_th 분포 폭 1.3배.
- 1차 데이터: 층별 V\_th 분포에서 해당 층만 프로그램 속도 느리고 분포 넓음. 전 웨이퍼·전 다이 재현(계통). erase는 정상.
- 가설 나열: (a) 데크 경계 채널 연결부 저항 증가(채널 전위 전달 지연), (b) 2차 채널 홀 하단 CD 확대(bowing) → 전계 감소, (c) 경계 부근 ONO 두께 증가(2차 홀 에치 후 잔류물 위 증착), (d) 2차 홀 오버레이 오차로 채널 단면 감소.
- 가설 검증: 단면 TEM에서 2차 홀 하단부 지름이 상부 대비 +15 nm 확대(bowing) 확인, ONO 두께 균일 → (c) 기각. 스트링 전류는 정상 → (a)(d) 기각. 홀 지름 증가로 곡률 감소 → 터널 산화막 전계 감소 → 같은 V\_pgm에 느린 프로그램.
- 근본 원인: 2차 데크 HAR 에치의 하단부 bowing(에치 종점 부근 이온 산란·폴리머 부족).
- 조치: 2차 홀 에치 종반 스텝의 바이어스·가스비 조정, 해당 층 V\_pgm 시작 전압 층별 오프셋 부여(펌웨어).
- 재발 방지: 데크 경계 부근 CD를 단면 계측 항목에 추가, 층별 프로그램 펄스 수를 웨이퍼 테스트 모니터로 등록.

#callout("트러블슈팅")[증상: NAND 특정 블록 그룹에서 program disturb fail 증가. 원인 후보: GSL 선택 Tr 누설(부스팅 전위 유출), 슬릿 정렬 오차로 GSL 폭 감소. 검증: GSL V\_th 분포가 해당 블록에서 낮음, 오버레이 데이터에서 슬릿 shift 확인. 조치: 슬릿 오버레이 보정, GSL 도핑·더미 WL 전압 조정.  *\[트러블슈팅\]* 증상: DRAM 웨이퍼 에지 다이에서 인접 셀 쌍 fail 급증(페어 패턴). 원인 후보: 커패시터 기둥 쓰러짐(에지 습식 제거 유속), 서포터 오픈 과다. 검증: top-view SEM 에지에서 기둥 접촉 확인, 서포터 두께 정상. 조치: 몰드 습식 제거 시 표면장력 저감(IPA 건조·초임계 건조), 에지 유속 조정.  *\[트러블슈팅\]* 증상: NAND 고온 베이크 후 상위 상태(P6, P7) V\_th 하향이 규격 초과, 하위 상태는 정상. 원인 후보: 트랩층 얕은 트랩 비율 증가(SiN 조성 Si-rich 편차), 측면 확산 증가. 검증: 베이크 온도별 손실의 E\_a와 조성 분석(XPS) → N/Si 비 저하. 조치: SiN ALD 전구체 비·온도 재설정, 프로그램 후 고온 안정화 단계 검토.]

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 7. 응용·심화(최신 이슈)

=== 7.1 DRAM: 1c nm급과 EUV

DRAM 1a~1c 세대(십수 nm급 half pitch)에서 EUV가 셀 어레이 핵심 층(활성 영역, BL, 커패시터 홀 등)에 도입되고 있다. 이득은 멀티 패터닝 스텝 감소와 오버레이 개선, 대가는 EUV 레지스트의 확률적 결함(stochastic defect)과 광자 샷 노이즈에 의한 LER, 그리고 비용이다. PE 관점에서는 확률적 결함이 무작위 단일 셀 fail로 나타나 리던던시 소모를 늘리는 새 유형의 tail이다.

=== 7.2 HBM: DRAM을 쌓으면 생기는 PE 이슈

- TSV(through-silicon via) 수천 개의 저항·누설·오픈, 마이크로 범프 접합 불량이 새 수율 항목.
- 적층 후 열: 코어 다이 8~16단이 쌓이면 상부 다이 온도가 하부보다 높아 retention 마진이 층별로 달라진다. 층별 refresh 관리와 온도 센서 기반 제어가 필요.
- KGD(known good die) 테스트 강화: 적층 후 한 다이 불량이 스택 전체를 폐기시키므로 웨이퍼 단계 스크린 기준이 일반 DRAM보다 엄격.
- HBM4: I/O 2048, 베이스 다이 로직 공정화, 하이브리드 본딩(범프 없는 Cu-Cu 직접 접합)으로 피치 축소·열 저항 감소 논의.

=== 7.3 3D DRAM 구조 후보

수직 적층 DRAM은 셀 Tr과 커패시터를 수평으로 눕혀 Si/SiGe 에피 적층에 만드는 방식(VS-DRAM 계열)이 유력하다. 과제: 수평 커패시터의 면적 확보(길이로 보상), 수백 층 에피 결정 품질, 층 선택 에치(SiGe 선택 제거)의 균일도, 층별 WL/BL 연결. 초기 세대는 수십 층부터 시작할 것으로 예상된다.

=== 7.4 NAND 300단 이상: 층 피치와 응력

- 층 피치(SiO₂ + WL 한 쌍) 축소: 40 nm대 → 30 nm대. WL 두께 감소로 저항 증가(W → Mo 검토), 층간 SiO₂ 얇아져 WL-WL 누설·커플링 증가.
- 스택 두께 10 μm 이상에서 응력·웨이퍼 휨이 오버레이를 해치고 채널 홀을 기울인다. 응력 상쇄 층, 저응력 몰드가 필요.
- 채널 홀 aspect ratio 100 이상: 극저온(cryogenic) 에치로 에치 속도와 프로파일을 동시에 확보하는 방향.
- 셀당 비트: QLC 주류화, PLC(5비트) 연구. 상태 폭 0.2 V 이하 요구.

=== 7.5 웨이퍼 본딩 NAND의 PE 관점

어레이와 CMOS를 따로 만들어 본딩하면 (a) CMOS를 어레이 열공정에서 해방해 고속 I/O(수 Gbps) 구현, (b) 두 웨이퍼 병렬 제조로 사이클 타임 단축, (c) 본딩 정렬·패드 접합 저항이라는 새 수율 항목이 생기고, (d) 두 웨이퍼 수율의 곱이 최종 수율이 되므로 KGD 전략이 중요해진다.

=== 7.6 신뢰성 지표의 시스템 연계

DRAM은 on-die ECC와 ECS(error check and scrub), PRAC으로 셀 결함을 시스템이 흡수한다. NAND는 LDPC·read retry·웨어 레벨링이 물리 한계를 보완한다. PE는 "공정 개선"과 "시스템 보완"의 경계를 이해해야 한다. 어디까지 공정으로 잡고 어디부터 ECC에 맡기는지가 비용·성능 결정이며, ECC 사용률 증가는 공정 열화의 선행 지표로 관리한다.

#callout("심화")[Self-boosting 물리: 프로그램 금지 스트링의 BL을 V\_cc로 두고 SSL을 닫으면 채널이 플로팅되고, 비선택 WL의 V\_pass 상승이 채널 전위를 커패시터 결합으로 끌어올린다(부스팅 비율 ≈ C\_ONO/(C\_ONO + C\_channel-substrate)). 채널 전위가 6~8 V로 올라가면 선택 WL의 V\_pgm 20 V와의 차가 12~14 V로 줄어 FN 전류가 수십~수백 배 감소한다. 이 부스팅 전위가 GSL/SSL 누설·접합 누설로 빠지면 program disturb가 된다. 3D의 얇은 poly 채널은 벌크 용량이 작아 부스팅 효율이 좋지만, 데크 경계·더미 WL 구간의 전위 불연속이 새로운 disturb 원인이다.]

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 8. 셀프 체크 질문

=== 개념(5)

+ DRAM 6F² 셀에서 F는 무엇이고 6F²는 어떻게 나오는가?
- 답: 결론: F는 최소 half pitch이고, 셀이 WL 방향 2F × BL 방향 3F를 차지해 6F²입니다. 근거: open BL 구조에서 활성 영역이 비스듬히 놓여 두 셀이 BL 콘택 하나를 공유하고, 두 WL이 활성 영역을 가로지릅니다. 예시: F가 약 13 nm이면 셀 면적 약 1000 nm²로, 이 위에 지름 30 nm대 커패시터를 세워야 하므로 높이 1 μm 이상이 필요합니다. 4F²는 수직 채널 트랜지스터로 BL 콘택 공유 없이 셀을 격자로 배치할 때 도달합니다.

+ BCAT를 도입한 이유 세 가지는?
- 답: 결론: 짧은 평면 길이에서 유효 채널 길이를 늘려 누설을 줄이고, WL을 묻어 BL·SN과의 커플링을 줄이고, 금속 WL로 저항을 낮추기 위해서입니다. 근거: 리세스 채널은 측벽·바닥을 따라 채널이 형성되어 유효 L이 수백 nm가 되고, 3면 게이트 제어로 DIBL·SS가 개선됩니다. 예시: 리세스 150 nm면 유효 L 300 nm 이상으로 F 수준 planar에서 불가능한 fA급 off 누설을 달성하며, 대가로 금속-접합 오버랩 GIDL을 이중 일함수 게이트로 잡아야 합니다.

+ 전하 공유 후 BL 전압 변화식을 쓰고 마진을 설명하라.
- 답: 결론: ΔV = (V\_SN − V\_BL)·C\_s/(C\_s + C\_BL)이며 SA 오프셋보다 충분히 커야 합니다. 근거: 셀 전하가 BL 용량과 나뉘므로 C\_s/C\_BL 비가 마진을 정하고, C\_BL은 BL에 매달린 셀 수와 층간막에 의존합니다. 예시: C\_s 10 fF, C\_BL 40 fF, 1.0 V 저장, 0.5 V 프리차지면 100 mV이고 오프셋 30 mV 대비 여유가 있지만, 누설로 0.7 V가 되면 40 mV로 마진이 거의 소진되어 이 시점이 retention 한계입니다.

+ FG와 CTF의 차이와 3D에서 CTF가 주력인 이유는?
- 답: 결론: FG는 도체에, CTF는 절연체 트랩에 전하를 저장하며, CTF가 얇고 간섭·단일 결함 내성이 좋아 3D 적층에 유리합니다. 근거: 도체 FG는 산화막 한 점 결함으로 전하를 전부 잃고 인접 FG와 커플링하지만, SiN 트랩 전하는 국소적이라 손실이 제한되고 커플링이 작습니다. 예시: 채널 홀 벽면에 ONO를 컨포멀 ALD로 한 번에 입히면 수백 층 셀이 동시에 만들어지는데 FG는 층마다 도체 패턴이 필요해 층 피치가 커집니다. 대가는 CTF의 얕은 트랩 초기 손실과 측면 확산입니다.

+ ISPP가 필요한 이유는?
- 답: 결론: 셀마다 프로그램 속도가 달라 한 번의 고전압으로는 V\_th 분포가 넓어지기 때문입니다. 근거: FN 전류는 전계에 지수적이므로 터널 산화막 두께나 홀 CD의 작은 차이가 큰 속도 차를 만들고, 작은 스텝으로 올리며 verify하면 각 셀이 목표 도달 시점에 멈춰 분포 폭이 스텝 폭 수준으로 좁아집니다. 예시: 스텝 0.3 V로 15~22 V까지 약 20여 펄스, 각 20 μs면 TLC tPROG 수백 μs가 되고, 스텝을 0.2 V로 줄이면 분포는 좁아지지만 펄스 수가 1.5배로 늘어 성능과 trade-off입니다.

=== 응용(5)

+ tRCD가 규격을 넘을 때 PE는 어떤 가설을 세우는가?
- 답: 결론: WL RC 지연, 셀 Tr on 전류 저하, C\_s 저하에 의한 센싱 지연 세 가지를 먼저 봅니다. 근거: tRCD는 WL 상승 + 전하 공유 + SA 센싱 시간의 합이라 각 단계의 물리 파라미터가 다릅니다. 예시: fail 행이 드라이버에서 먼 쪽에 몰리면 WL 저항(W 보이드), 웨이퍼 에지에 몰리고 저온에서 심하면 V\_th 높음(리세스 깊이), 마진 테스트에 민감하고 위치 무작위면 C\_s 문제로 좁혀 각각 사행선 저항, V\_th 맵, 커패시터 C-V로 검증합니다.

+ 음 WL off 전압과 GIDL의 trade-off를 retention 데이터로 어떻게 확인하나?
- 답: 결론: V\_WL(off)을 스윕하며 tail 셀 수를 측정하면 U자 곡선이 나오고, 최소점 양쪽의 셀이 다른 기구입니다. 근거: 전압을 내리면 subthreshold 누설 셀은 줄고 GIDL 셀은 늘어나며, 온도 의존(E\_a)도 각각 0.5~0.6 eV와 0.3 eV 이하로 다릅니다. 예시: −0.15 V에서 tail 300개, −0.3 V에서 200개, −0.45 V에서 400개면 최적은 −0.3 V 근처이고, −0.45 V에서 늘어난 셀의 E\_a가 낮으면 GIDL형으로 판정해 WL 에치백·오버랩을 점검합니다.

+ NAND 상부 층과 하부 층 셀 특성이 다른 이유와 대응은?
- 답: 결론: 채널 홀이 테이퍼져 상하 CD가 다르고 그에 따라 터널 산화막 전계와 셀 면적이 달라지기 때문입니다. 근거: 홀 지름이 작으면 곡률이 커서 같은 전압에 전계가 강해 프로그램이 빠르고 셀 면적이 작아 전자 수는 적으며, 반대로 큰 홀은 느립니다. 예시: 상부 100 nm, 하부 80 nm면 하부가 빨라 층별 V\_th 분포가 수백 mV 어긋날 수 있어, 에치 프로파일 개선과 함께 WL 그룹별 V\_pgm 시작 전압·read 레벨 오프셋을 펌웨어에서 보정합니다.

+ Program disturb와 read disturb를 어떻게 구분해 분석하나?
- 답: 결론: 피해 셀의 위치와 스트레스 종류로 구분합니다. 근거: program disturb는 프로그램 중 같은 WL의 금지 스트링 셀에서 부스팅 누설로 발생해 프로그램 직후 나타나고, read disturb는 읽기 반복에 따라 같은 블록 비선택 WL의 erased 셀이 서서히 올라갑니다. 예시: 블록을 프로그램만 하고 바로 읽어 erased 셀 V\_th 상승이 있으면 program disturb, 10만 회 읽은 뒤에만 상승하면 read disturb이고, 전자는 GSL/SSL 누설·V\_pass, 후자는 V\_pass 최소화·블록 refresh로 대응합니다.

+ DRAM과 NAND에서 "GIDL"의 역할이 어떻게 다른가?
- 답: 결론: DRAM에서는 retention을 깎는 누설이고, 3D NAND에서는 erase에 정공을 공급하는 도구입니다. 근거: 두 경우 모두 게이트-드레인 오버랩 고전계의 BTBT지만, DRAM 셀은 저장 노드 전하를 지켜야 하고 NAND 3D 채널은 벌크가 없어 정공을 만들 다른 방법이 없습니다. 예시: DRAM은 이중 일함수 WL로 GIDL을 줄이고, NAND는 GSL/SSL 접합 프로파일을 GIDL이 잘 나도록 설계하며 erase 속도가 부족하면 이 부분을 점검합니다.

=== 심화(5)

+ VRT가 왜 스크린이 어렵고 어떻게 대응하나?
- 답: 결론: 결함의 전하 상태가 무작위로 바뀌어 테스트 시점에 정상인 셀이 필드에서 불량이 될 수 있어 완전 스크린이 불가능합니다. 근거: 공핍층 내 단일 트랩의 상태 전환은 random telegraph 성격으로 시간 상수가 초~시간 단위로 넓게 분포합니다. 예시: 웨이퍼 테스트에서 retention 2 s였던 셀이 필드에서 100 ms로 바뀌면 refresh 64 ms에 걸리진 않지만 마진이 사라지고, 그래서 DDR5는 on-die ECC와 ECS로 1비트 fail을 흡수하며, 고온·전계 스트레스로 상태 전환을 유도하는 스크린이 보조로 쓰입니다.

+ Row hammer 한계 횟수가 세대마다 낮아지는 이유와 PRAC은?
- 답: 결론: 셀 피치가 줄어 WL 간 커플링과 캐리어 이동 거리가 짧아져 같은 반복 횟수에 더 많은 전하가 빠지기 때문이고, PRAC은 행별 활성화 횟수를 세어 임계 초과 시 인접 행 refresh를 요청하는 DDR5 기능입니다. 근거: hammer 기구는 WL 토글에 의한 캐리어 주입·이동이 인접 저장 노드에 도달하는 것이므로 거리에 민감합니다. 예시: DDR3 시절 10만 회대에서 최신 세대 수천~수만 회로 낮아져 TRR로 부족해졌고, PRAC은 카운터를 DRAM 내부에 두어 컨트롤러 추정 없이 정확히 대응합니다.

+ 3D NAND에서 erase 포화가 생기는 이유와 대책은?
- 답: 결론: erase 전계가 커지면 게이트에서 블로킹 산화막을 통해 전자가 트랩층으로 역주입되어 전하 제거가 상쇄되기 때문입니다. 근거: CTF는 트랩층과 게이트 사이가 얇은 절연막이므로 채널 쪽 전자 방출과 게이트 쪽 전자 주입이 동시에 일어나 평형에 도달하면 V\_th가 더 내려가지 않습니다. 예시: 블로킹 층에 밴드갭 8.8 eV, κ 9의 Al₂O₃를 넣으면 같은 전압에서 블로킹 쪽 전계가 낮아지고 장벽이 높아 역주입이 줄어 깊은 erase가 가능하며, Al₂O₃가 얇아진 로트에서 erase 후 V\_th가 높게 남는 현상으로 확인됩니다.

+ 웨이퍼 본딩 NAND가 PUC보다 유리한 점과 새 리스크는?
- 답: 결론: CMOS를 어레이 열공정에서 분리해 고속 주변회로를 쓸 수 있고 병렬 제조가 가능하지만, 본딩 정렬·접합 수율과 두 웨이퍼 수율의 곱이 새 리스크입니다. 근거: PUC는 주변 Tr이 수백~1000°C 근접 어레이 공정을 겪어 성능 제약이 있으나 본딩은 그 제약이 없습니다. 예시: 본딩 정렬 오차가 수백 nm 이내여야 수백만 개 패드가 연결되고, 어레이 웨이퍼 수율 90%와 CMOS 수율 95%면 최종 85% 이하가 되므로 본딩 전 KGD 테스트 전략이 핵심이 됩니다.

+ 3D DRAM이 3D NAND처럼 쉽게 적층되지 못하는 이유는?
- 답: 결론: DRAM 셀은 단결정 Si 트랜지스터와 10 fF 커패시터를 요구해 NAND처럼 증착 poly 채널과 얇은 트랩층으로 대체할 수 없기 때문입니다. 근거: fA급 누설을 위해 결정 결함 없는 채널이 필요해 Si/SiGe 에피 적층과 선택 에치가 요구되고, 수평으로 눕힌 커패시터는 면적 확보를 길이로 해야 해 층당 면적 이득이 제한됩니다. 예시: 초기 3D DRAM은 수십 층 수준에서 시작될 것으로 예상되며, IGZO 채널로 누설 요구를 완화하거나 2T0C로 커패시터를 없애는 접근이 함께 연구됩니다.

#line(length: 100%, stroke: 0.4pt + rgb("#CCCCCC"))

== 9. 한 페이지 요약

#table(
  columns: 3,
  align: left,
  table.header(
    [*주제*],
    [*DRAM 핵심*],
    [*NAND 핵심*],
  ),
  [셀],
  [1T1C, 6F², BCAT + TiN/ZAZ/TiN 원통 커패시터 약 10 fF],
  [CTF 1T, 채널 홀 벽면 ONO, poly macaroni 채널, W 치환 WL],
  [저장],
  [전하 유무(fC), 파괴적 읽기 + 복원],
  [트랩 전하 → V\_th(수 V 창), 비파괴 읽기],
  [쓰기],
  [BL → 셀 충전, WL V\_PP 부스트, ns],
  [FN 터널링 ISPP 15~24 V, 수백 μs~ms],
  [지우기],
  [없음(덮어쓰기)],
  [블록 GIDL erase, 수 ms],
  [읽기 마진],
  [ΔV = ΔV\_cell·C\_s/(C\_s + C\_BL) ≈ 100 mV vs SA 오프셋 30 mV],
  [인접 V\_th 분포 간격 0.3~0.5 V(TLC), σ 0.1 V 이하],
  [유지],
  [64 ms(85°C), refresh tREFI 3.9 μs(DDR5)],
  [수 년(40°C), 베이크로 가속(E\_a 약 1.1 eV)],
  [타이밍],
  [tRCD·tRP 약 16 ns, tRAS 32, tWR 30, tRFC 295 ns(16 Gb)],
  [tR 50~90 μs(TLC), tPROG 0.5~1 ms, tBERS 2~5 ms],
  [대표 불량],
  [retention tail, VRT, row hammer, tWR/tRCD, 커패시터 쇼트·누설],
  [V\_th 분포 확대·shift, program/erase fail, 3종 disturb, retention, endurance],
  [누설/열화 물리],
  [subthreshold·GIDL·접합·유전체 누설의 합],
  [터널 산화막 트랩 생성, 얕은 트랩 탈출, 측면 확산],
  [구제],
  [리던던시 + on-die ECC + PRAC/RFM],
  [LDPC + read retry + soft read + 웨어 레벨링],
  [공정 난제],
  [HAR 커패시터(AR 50~100) 쓰러짐, 셀 Tr fA 누설, 열 예산],
  [HAR 채널 홀(AR 60~100 이상) 프로파일, 층별 균일도, 응력, 데크 정렬],
  [공정→특성],
  [리세스 깊이→V\_th·I\_off, 오버랩→GIDL, 홀 CD·ZAZ→C\_s, pre-clean→R\_c→tWR],
  [홀 CD→층별 V\_th, ONO 두께→속도·retention, W 채움→tR, GSL/SSL→erase·disturb],
  [제품],
  [DDR5, LPDDR5X, GDDR7, HBM3E/HBM4],
  [TLC/QLC SSD, UFS, 엔터프라이즈],
  [미래],
  [4F² VCT, 3D DRAM, IGZO/2T0C, HKMG 주변, 하이브리드 본딩],
  [300~500단, 층 피치 축소(Mo WL), QLC/PLC, 웨이퍼 본딩, 극저온 에치],
  [한 줄],
  [빠르지만 새는 전하를 지키는 싸움],
  [오래 가두지만 장벽이 상하는 전하를 관리하는 싸움],
)
