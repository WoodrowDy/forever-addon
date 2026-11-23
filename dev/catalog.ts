// WoWSims proto IDs. Source allowlists deliberately exclude raids and seasonal bosses.
export const armorSlots = [0, 2, 4, 5, 6, 7, 8, 9];
const zones: Record<number, string> = {
  1583: "검은바위 첨탑",
  1584: "검은바위 나락",
  2017: "스트라솔름",
  2057: "스칼로맨스",
  2557: "혈투의 전장",
  2100: "마라우돈",
};
const bosses = new Set([
  9196, 9217, 9218, 9219, 9236, 9237, 9568, 9596, 9718, 9736, 9816, 10220,
  10264, 10268, 10339, 10363, 10376, 10429, 10430, 10509, 10584, 10596, 10899,
  8923, 8929, 8983, 9016, 9017, 9018, 9019, 9024, 9025, 9027, 9028, 9029, 9030,
  9031, 9032, 9033, 9034, 9041, 9042, 9056, 9156, 9319, 9476, 9502, 9938, 10393,
  10435, 10436, 10437, 10438, 10439, 10440, 10516, 10558, 10808, 10809, 10811,
  10812, 10997, 11032, 11143, 10432, 10433, 10502, 10503, 10504, 10505, 10506,
  10507, 10508, 10901, 11261, 11622, 1853, 11467, 11486, 11487, 11488, 11489,
  11490, 11492, 11496, 11501, 13280, 14321, 14322, 14323, 14324, 14325, 14326,
  14327, 14354, 12201, 12203, 12225, 12236, 12237, 12258, 13282, 13596, 13601,
]);
const koBoss: Record<number, string> = {
  9027: "광신자 고로쉬",
  9028: "그리즐",
  10508: "라스 프로스트위스퍼",
  9816: "불의수호자 엠버시어",
  10220: "할리콘",
  10505: "조교 말리시아",
  10430: "괴수",
  9019: "제왕 다그란 타우릿산",
  10440: "남작 리븐데어",
  14324: "고르독 공물",
  9938: "마그무스",
  10363: "사령관 드라키사스",
  12201: "공주 테라드라스",
  1853: "암흑스승 간들링",
};
// Additional documented sources (see SOURCES.md). Only tradeable finished crafts in this list.
const extra: Record<number, string> = {
  277117: "검은바위 나락 · 그리즐",
  280056: "검은아귀 요새 · 간수 임판",
  280057: "검은아귀 요새 · 간수 임판",
  280082: "검은아귀 요새 · Mopes",
  15411: "퀘스트 · 꿈속에서",
  13965: "퀘스트 · 호드의 용사 / 사령관 드라키사스 처치",
  13968: "퀘스트 · 호드의 용사 / 사령관 드라키사스 처치",
  252605: "제작 · 가죽세공",
  252604: "제작 · 가죽세공",
  252484: "제작 · 가죽세공",
  252606: "제작 · 가죽세공",
  252486: "제작 · 가죽세공",
  19050: "제작 · 재봉술",
  19059: "제작 · 재봉술",
  18405: "제작 · 재봉술",
  12632: "제작 · 대장기술",
  12784: "제작 · 대장기술",
  280018: "Shaper's Terrace · Thunderhoof",
  19323: "알터랙 계곡 · 확고한 동맹",
  19325: "알터랙 계곡 · 확고한 동맹",
  19315: "알터랙 계곡 · 확고한 동맹",
};
const names: Record<number, string> = {
  277117: "잔인한 검투사의 어깨보호구",
  11726: "잔인한 검투사 사슬 갑옷",
  14503: "죽음의 손아귀",
  12927: "명중의 어깨보호대",
  11815: "심판의 손길",
  280056: "불꽃절단 초승달 도끼",
  272437: "적응성 전투 보조기",
  14612: "피고리 다리보호대",
  14615: "피고리 건틀릿",
  14616: "피고리 장화",
  14614: "피고리 허리띠",
};
const pix = new Set([
  272411, 272414, 272410, 272406, 272407, 272437, 272438, 272431, 272432,
  272433,
]);
export type Item = {
  id: number;
  name: string;
  source: string;
  armor: number;
  type: number;
  hand: number;
  weapon: number;
  rating: Record<string, number>;
  dps: number;
  quality: number;
  icon: string;
  set: number;
  category: number;
  rep: boolean;
  unique: boolean;
};
export function catalog(db: any): Item[] {
  const npc = new Map<number, string>(
    db.npcs.map((x: any) => [x.id, x.name.trim()]),
  );
  const result: Item[] = [];
  for (const x of db.items) {
    const opt = x.scalingOptions?.["0"];
    if (
      !opt ||
      opt.ilvl < 48 ||
      (x.reqLvl ?? 0) > 60 ||
      x.phase !== 1 ||
      x.quality < 3 ||
      x.quality > 4 ||
      x.armorType === 4 ||
      x.randomSuffixOptions?.length ||
      x.factionRestriction ||
      x.requiredProfession ||
      (x.classAllowlist && !x.classAllowlist.includes(7)) ||
      (x.type === 14 && x.rangedWeaponType !== 8) ||
      (x.type === 13 && ![1, 2, 3, 4, 5, 7, 8].includes(x.weaponType))
    )
      continue;
    const sources = x.sources ?? [];
    const drops = sources
      .map((s: any) => s.drop)
      .filter(
        (d: any) => d && !d.faction && zones[d.zoneId] && bosses.has(d.npcId),
      );
    let source = extra[x.id],
      rep = [19323, 19325, 19315].includes(x.id);
    if (x.id >= 227001 && x.id <= 227024 && x.setId === 1679) {
      const stage = (
        { 6: 1, 7: 2, 8: 2, 3: 3, 9: 3, 10: 3, 1: 4, 5: 4 } as Record<
          number,
          number
        >
      )[x.type];
      if (!stage) throw Error("Unknown Five Thunders slot");
      source = "T0.5 연퀘 " + stage + "단계 · 델리아나 / 모크바르";
      rep = stage === 4;
    }
    if (!source && drops.length) {
      const first = drops[0];
      source =
        zones[first.zoneId] +
        " · " +
        (koBoss[first.npcId] ?? npc.get(first.npcId)) +
        (drops.length > 1 ? " 외" : "");
    }
    if (pix.has(x.id) && sources.some((s: any) => s.soldBy?.npcId === 227853))
      source = "픽스 시직스 · 빛바랜 언더마인화";
    const reputation = sources.find(
      (s: any) => s.rep?.repFactionId === 2819,
    )?.rep;
    if (reputation) {
      rep = true;
      source =
        "The Watchers · " +
        ({ 5: "약간 우호", 6: "우호", 7: "매우 우호", 8: "확고한 동맹" }[
          reputation.repLevel
        ] ?? "평판");
    }
    if (!source) continue;
    result.push({
      id: x.id,
      name: names[x.id] ?? x.name,
      source,
      armor: x.armorType ?? 0,
      type: x.type,
      hand: x.handType ?? 0,
      weapon: x.weaponType ?? 0,
      rating: opt.stats ?? {},
      dps: opt.unroundedDps ?? 0,
      quality: x.quality,
      icon: x.icon ?? "",
      set: x.setId ?? 0,
      category: x.limitCategory ?? 0,
      rep,
      unique: !!x.unique,
    });
  }
  if (result.some((x) => x.id === 279260))
    throw Error("Raid-reagent craft in the pre-raid pool");
  if (
    !result.some((x) => x.id === 277117) ||
    !result.some((x) => x.id === 11726)
  )
    throw Error("Missing reference items");
  return result.sort((a, b) => a.id - b.id);
}

// Enforce equipment rules again after recombining independently scored slot groups.
export function validateGear(gear: number[], byId: Map<number, Item>): void {
  if (gear.length !== 17) throw Error("Expected 17 gear positions");
  const slots = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 11, 12, 12, 13, 13, 14];
  const categories = new Set<number>();
  const ids = new Set<number>();
  for (const [slot, id] of gear.entries()) {
    if (!id && slot === 15) continue;
    const item = byId.get(id);
    if (!item || item.type !== slots[slot])
      throw Error("Invalid item for slot " + slot + ": " + id);
    if (item.unique && ids.has(id)) throw Error("Duplicate unique item " + id);
    if (item.category && categories.has(item.category))
      throw Error("Duplicate equipment category " + item.category);
    ids.add(id);
    if (item.category) categories.add(item.category);
  }
  if (ids.has(13965) && ids.has(13968))
    throw Error("Conflicting quest rewards");
  if ((byId.get(gear[14])!.hand === 4) !== (gear[15] === 0))
    throw Error("Invalid weapon layout");
  if (gear[15] && ![5, 7].includes(byId.get(gear[15])!.weapon))
    throw Error("Invalid Shaman off-hand");
}
