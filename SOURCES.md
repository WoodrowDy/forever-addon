# 데이터 출처

엔진과 캐릭터 능력치, 아이템 ID, 장비 제한과 룻 테이블은 같은 WoWSims 리비전을 사용합니다. 다음 링크는 최초 릴리스의 근거입니다.

- [고정된 WoWSims 리비전](https://github.com/wowsims/forever/tree/a73af7145111ce19c621e3b5f678553adf326907)
- [아이템 DB](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/assets/database/db.json)
- [고양·정기 기본 전투 프로필](https://github.com/wowsims/forever/tree/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/shaman)
- [포에버 세트 효과 구현](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/sim/common/forever/items_sets.go)
- [검투사 세트의 공포 적중 감소](https://www.forever-xp.com/items/11726/) 및 [그리즐의 사슬 어깨, 고로쉬의 사슬 갑옷](https://wowtbc.gg/warcraftforever/loot-tables/dungeons/blackrock-depths/)
- [포에버 고술 던전·퀘스트·양손 무기](https://www.wowhead.com/forever/guide/classes/shaman/enhancement/bis-gear), [포에버 정술 장비](https://wowforever.be/bis/forever/preraid/shaman-elemental/), [포에버 복술 장비](https://wowforever.be/bis/forever/preraid/shaman-restoration/)
- [T0.5 특성별 보상 및 마지막 단계 평판 조건](https://conquestcapped.com/guides/wow-forever/wow-forever-tier-0-5-questline/)
- [빛바랜 언더마인화와 픽스 시직스](https://www.wowhead.com/forever/guide/currency/tarnished-undermine-real-overview)
- [간수 임판 전리품](https://www.wowhead.com/forever/npc=247206)
- [대장기술 제조법 및 재료](https://www.wowhead.com/forever/guide/professions/blacksmithing/overview)와 [공격대 재료 Malleable Essence of Nature](https://wowforever.ninja/items/274030-malleable-essence-of-nature/). 숲 수호자의 도끼는 이 재료를 소모하여 프리레이드 후보에서 제외했습니다.
- [포에버 가죽세공 재료](https://warcraftforever.games/professions/leatherworking) 및 [Pristine Scale 획득처](https://warcraft.wiki.gg/wiki/Pristine_Scale)
- [하급 치유의 물결 6단계의 기본 수치와 치유 계수](https://wowforeverbuilder.com/classes/shaman/spells/lesser-healing-wave/), [정화 및 해일의 집중 효과](https://lorddemonos.github.io/wow-forever/healing/shaman/)

게임 안 캐릭터 장비·인벤토리 또는 유저 로그를 외부로 전송하는 기능은 없습니다. 아이템 이름과 툴팁은 가능하면 실행 중인 게임 클라이언트에서 읽습니다.

## 적중과 드루이드 EP

- 레이드 비교 기준과 특성별 보정은 [Method](https://www.method.gg/wow-forever/how-does-hit-chance-work-in-wow-forever), [WoWF 주술사](https://wowf.io/en/talents/shaman), [WoWF 드루이드](https://wowf.io/en/talents/druid)를 참조합니다.
- 조화는 [WoWSims PreBiSEpWeights](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/druid/balance/presets.ts), 표범은 [CatEp / BearEp](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/druid/feral_ep.ts)의 장비 기본 능력치와 무기 DPS를 사용합니다. 곰은 BearEp의 방어 성분만 후보 선별에 씁니다. 회복 드루이드의 지속 HPS는 단일 주문·고정 MP5 모델입니다.

- [WoWSims 드루이드 역할 프로필](https://github.com/wowsims/forever/tree/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/druid), [TMI 산식](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/sim/core/metrics_aggregator.go), [치유의 손길 주문 9889 수치](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/sim/core/spelldata/spells_auto_gen.go)

## 후보 선별과 측정 조건

딜 전투의 기준 시간(300초)과 변동 폭(±20%)은 [SimulationCraft 전투 옵션](https://github.com/simulationcraft/simc/wiki/Options)에 맞췄습니다. WoWSims Forever는 각 반복에서 범위 내 전투 시간을 난수로 선택합니다. 특성·기술·발동·행동 우선순위와 DPS 결과는 WoWSims Forever 기준입니다.

두 직업은 같은 WoWSims DB와 페이즈·레벨·품질·획득처 기준을 사용합니다. 드루이드의 가죽·천, 반지·장신구 쌍, 무기와 우상은 독립적으로 수집합니다. WOWF 비교 목록에서 누락된 아이템은 갱신 로그에 역할·부위·ID·첫 제외 사유를 남깁니다. 자동 수집 범위는 등록한 획득처에 한정되며 제작품은 확인한 목록을 사용합니다. 드루이드는 적중 평점과 다른 재질 수별로 EP 상위 조합을 생성하고, 재질 수와 1% 간격의 적중 목표별 상위 2개를 모아 실제 평가합니다. 순위·고정·교체는 수록된 최종 후보 내에서 지원합니다. 표본 수에 따른 측정 오차가 있습니다.

아이템 툴팁 EP는 후보 선별용 점수입니다. 곰은 기존 가중치에서 방어 능력치만 사용합니다. 회드는 치유력·고정 MP5·지능에 각각 1·1.86·0.77의 선별 가중치를 둡니다. 이 가중치는 제작자가 설정한 근삿값입니다.

복술은 기존 참조 빌드의 하급 치유의 물결 6단계, 회드는 무특성 치유의 손길 10단계(기본 평균 1946.4, 치유력 계수 1, 기본 3.5초, 마나 755)로 비교합니다. 회드 엔진은 장비 능력치만 제공하므로 두 힐러의 지속 HPS는 애드온의 단일 주문 계산값입니다. 고정 MP5를 초당 균등 회복으로 처리하고 초과 치유, 정신력 회복, 소모품, HoT 중첩, 발동에 의한 마나 수급은 제외합니다. 종료 마나는 해당 조건의 추정치입니다.

WoWSims Forever의 해당 특성 기본 특성·버프·소모품·딜 사이클을 사용합니다. 타우렌 60레벨, 우두머리 63레벨 하나, 평균 300초(±60초), 무마부, 무기 스왑 해제, 세트당 1,600회로 통일했습니다. 수치 옆 계산 조건에 표준오차도 표시합니다.

하급 치유의 물결 6단계를 단일 대상에게 연속 시전한다고 가정합니다. 평균 기본 치유 820, 치유력 계수 0.429, 기본 시전 1.5초, 마나 380을 사용합니다. 정화 5점과 해일의 집중 5점을 적용하며 평균 1회 치유량에 주문 극대화, 시전 HPS에 주문 가속이 반영됩니다. 1회 마나는 361입니다. 초과 치유, 물의 보호막, 일시 발동, 연쇄 치유는 이 수치에서 제외됩니다.

두 직업의 장비 ID와 기본 획득처는 고정 버전의 WoWSims 아이템 DB에서 가져옵니다. 던전·보스, 퀘스트, 제작, 상인·평판 후보의 포함 조건과 개별 보완 출처는 저장소에서 확인할 수 있습니다. [공통 선별 기준](dev/catalog.ts) · [드루이드 수집기](dev/druid_catalog.ts)

드루이드 장비의 독립 대조 목록은 역할별 WOWF.IO 페이지입니다. [조화](https://wowf.io/ko/bis/druid/balance) · [표범](https://wowf.io/ko/bis/druid/feral-dps) · [곰](https://wowf.io/ko/bis/druid/feral-tank) · [회복](https://wowf.io/ko/bis/druid/restoration)

주술사 초기 목록은 WoWSims Forever의 페이즈 1 아이템과 획득 경로에서 선별한, 아이템 레벨 48 이상의 고정 능력치 희귀·영웅 장비입니다. 검은바위 나락·첨탑, 스칼로맨스, 스트라솔름, 혈투의 전장, 마라우돈의 지정 보스와 검은아귀 요새 등 확인한 개별 경로를 담았습니다. 일부 제작품, 양 진영 공통 보상, 평판, 던전 화폐 상점, 주술사 T0.5 연퀘도 포함합니다. 랜덤 수식어 아이템, 확인 전인 획득처, 공격대 재료가 필요한 제작품은 범위 밖입니다. 구간별 연퀘 보상은 해당 특성용 버전을 선택합니다.

장신구와 반지 쌍, 양손 또는 한손+보조장비를 하나의 선택 단위로 만듭니다. 고유 착용, 동일 제한 분류, 서로 배타적인 퀘스트 장신구를 검사합니다. 각 특성의 스탯 가중치로 후보를 좁힌 뒤 적중·숙련 상한을 고려해 세트를 구성합니다. 후보를 교체하고 주요 세트를 따로 시험한 뒤, 실측 상위 조합의 부위를 다시 결합해 평가합니다. **표시 순위는 이 탐색으로 평가한 조합 내 순위**입니다. 조건이나 고정 장비를 바꾸면 게임 안에서는 이미 평가한 전체 세트에서 다시 선택합니다.

### WoWF 고양 추천과의 대조

[WoWF 고양 추천](https://wowf.io/ko/bis/shaman/enhancement)의 장비는 아이템별로 수록 조건을 대조합니다. 제공된 추천 화면과 WoWSims DB에서 확인한 성난하늘 투구(20134)와 강력한 오우거의 부적목걸이(22150)는 퀘스트 보상으로 포함합니다. 같은 화면의 대지매듭 망토(21187)와 대지력의 고리(21182)는 기준 DB의 페이즈가 2여서 페이즈 1 비교에서 제외합니다. 사이트와 DB의 가용 범위가 다를 수 있습니다. 확인된 13개 아이템과 양손 무기 구성을 함께 고정하고, 남은 망토·반지 두 자리는 기존 측정 후보의 조합으로 보완해 별도 측정합니다.

고양은 EP로 추린 후보의 측정이 끝나면 장비 적중 8%를 충족한 올사슬과 혼합 착용 세트에서 각각 평균 DPS가 가장 높은 세트를 찾습니다. 이 두 세트의 방어구 여덟 부위를 수록 가능한 같은 부위 아이템으로 하나씩 교체해 측정하고, 새 결과를 포함해 한 번 더 반복합니다.

WoWF의 [고양 부위별 후보](https://wowf.io/en/bis/shaman/enhancement)에 있는 데빌사우루스 장갑·다리, 전투곰 다리, 나무구렁 허리·장갑도 가죽세공 후보로 수록합니다. [데빌사우루스 재료](https://timesaver.gg/blog/wow-forever-devilsaur-leather-farm) · [나무구렁 장갑 재료](https://www.wowhead.com/forever/spell=23704/timbermaw-brawlers)

2026-11-25 영문 WoWF 페이지에서 Painweaver Band를 사용한 추천 세트도 동일한 고술 참조 빌드에서 별도로 대조했습니다. 슬롯 순서의 ID는 `20134,15411,227019,13340,252484,22668,19049,272410,15065,275618,21182,13098,13965,11815,19169,0,22395`입니다. WoWSims 장비 적중은 1%, 4~6분 × 1,600회의 평균은 812.34 DPS입니다. 대지력의 고리·손목·일몰이 기준 DB의 페이즈 2이므로 이 완성 세트는 프리레이드 추천 후보에 포함하지 않습니다.

## 적중 가능 범위와 딜 재측정

등록된 착용 가능 아이템을 부위별로 묶고, 반지·장신구 쌍과 무기 조합에서 고유 착용 및 상호 배타 보상을 검사합니다. 고정 부위가 있으면 그 부위의 그룹에서 고정을 만족하는 최대 적중을 사용합니다. 최대 적중은 등록 아이템 기준이며 세트 보너스·외부 버프는 직접 입력한 장비 목표에 맞춰 별도로 다룹니다.

평균 DPS의 순위는 1,600회 측정값으로 계산합니다. 네 딜 전문화에서 0부터 레이드 상한까지 1% 단위 장비 목표로 조회하고 기본 필터에서 서로 다른 추천 세트의 차이가 양쪽 표준오차 합의 두 배 이내면 각 세트를 독립 난수로 6,400회 다시 측정합니다. 이 확인용 표본은 최초 순위 선정에 쓰이지 않습니다. 두 독립 평균 차이의 약 95% 오차 폭은 1.96 × √(SE₁² + SE₂²)입니다. 고정·미리보기에서 처음 등장한 후보는 확인용 표본이 없을 수 있습니다.
