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
- 조화는 [WoWSims PreBiSEpWeights](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/druid/balance/presets.ts), 표범·곰은 [CatEp / BearEp](https://github.com/wowsims/forever/blob/a73af7145111ce19c621e3b5f678553adf326907/ui/specs/druid/feral_ep.ts)의 장비 기본 능력치와 무기 DPS를 사용합니다. 회복 드루이드의 치유력 기준은 이 애드온의 단순 비교 기준입니다.
