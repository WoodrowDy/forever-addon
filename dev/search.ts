import { armorSlots, type Item } from "./catalog.ts";
export type Spec = "enhancement" | "elemental" | "restoration";
export const specs: Spec[] = ["enhancement", "elemental", "restoration"];
const weights: Record<Spec, Record<number, number>> = {
  enhancement: {
    0: 2.2,
    1: 1.32,
    3: 1.99,
    14: 1,
    17: 5.2,
    18: 2.42,
    19: 2.81,
    21: 3.5,
    20: 0.37,
    5: 1.27,
    10: 0.72,
    12: 2.52,
  },
  elemental: {
    3: 0.19,
    13: 0.02,
    5: 1,
    7: 0.31,
    10: 0.69,
    12: 1.81,
    17: 1.18,
    18: 0.61,
    19: 1.23,
    31: 0.04,
  },
  restoration: { 4: 1, 3: 0.1, 18: 0.55, 19: 0.75, 31: 0.12 },
};
const emphasis: Record<Spec, number[]> = {
  enhancement: [
    277117, 14503, 12927, 11726, 14615, 14614, 14612, 14616, 11815, 272437,
    280056, 280018, 12784, 19323, 13965, 22395, 272432,
  ],
  elemental: [
    277117, 14503, 11726, 12930, 13968, 272438, 272433, 272432, 280082,
  ],
  restoration: [277117, 11726, 23200, 272431, 272407, 18371],
};
type Option = { ids: number[]; value: number; hit: number; exp: number };
function pairable(a: Item, b: Item) {
  return (
    !(a.id === b.id && a.unique) &&
    !(a.category && a.category === b.category) &&
    !([13965, 13968].includes(a.id) && [13965, 13968].includes(b.id))
  );
}
export function search(items: Item[], spec: Spec) {
  const gears = new Map<string, number[]>(),
    byID = new Map(items.map((i) => [i.id, i]));
  const wanted = new Set(emphasis[spec]);
  const statWeights = weights[spec],
    hitCap = spec === "enhancement" ? 80 : 170;
  const single = (a: Item) =>
    Object.entries(a.rating).reduce(
      (n, [k, v]) => n + (statWeights[+k] ?? 0) * v,
      0,
    ) + (spec === "enhancement" ? 14.18 * a.dps : 0);
  function option(ids: number[]): Option {
    let value = 0,
      hit = 0,
      exp = 0;
    for (const id of ids) {
      const a = byID.get(id);
      if (a) {
        value += single(a);
        hit += a.rating[17] ?? 0;
        exp += a.rating[21] ?? 0;
      }
    }
    return { ids, value, hit, exp };
  }
  function score(opts: Option[]) {
    let value = 0,
      hit = 0,
      exp = 0;
    for (const o of opts) {
      value += o.value;
      hit += o.hit;
      exp += o.exp;
    }
    return (
      value -
      Math.max(0, hit - hitCap) * (statWeights[17] ?? 0) -
      Math.max(0, exp - 65) * (statWeights[21] ?? 0)
    );
  }
  for (const mail of [true, false])
    for (const withRep of [false, true])
      for (const tier of [false, true]) {
        const tierStart = {
          elemental: 227001,
          restoration: 227009,
          enhancement: 227017,
        }[spec];
        const pool = items.filter(
          (x) =>
            (x.set !== 1679 ||
              (tier && x.id >= tierStart && x.id < tierStart + 8)) &&
            (withRep || !x.rep) &&
            (!mail || !armorSlots.includes(x.type - 1) || x.armor === 3),
        );
        const group: Option[][] = Array.from({ length: 10 }, (_, n) =>
          pool.filter((x) => x.type === n + 1).map((x) => option([x.id])),
        );
        for (const t of [11, 12]) {
          const candidates = pool.filter((x) => x.type === t),
            paired: Option[] = [];
          for (let n = 0; n < candidates.length; n++)
            for (let j = n; j < candidates.length; j++) {
              if (pairable(candidates[n], candidates[j]))
                paired.push(option([candidates[n].id, candidates[j].id]));
            }
          group.push(paired);
        }
        const weapons: Option[] = [];
        for (const main of pool.filter(
          (x) =>
            x.type === 13 &&
            [1, 2, 4].includes(x.hand) &&
            ![5, 7].includes(x.weapon),
        )) {
          if (main.hand === 4) {
            weapons.push(option([main.id, 0]));
            continue;
          }
          for (const off of pool.filter(
            (x) => x.type === 13 && [5, 7].includes(x.weapon),
          ))
            if (pairable(main, off)) weapons.push(option([main.id, off.id]));
        }
        group.push(
          weapons,
          pool.filter((x) => x.type === 14).map((x) => option([x.id])),
        );
        if (group.some((g) => !g.length))
          throw Error("Incomplete equipment pool: " + spec);
        for (const g of group)
          g.sort(
            (a, b) =>
              b.value - a.value || a.ids.join().localeCompare(b.ids.join()),
          );
        function improve(initial: Option[], pinned = -1) {
          const fit = initial.slice();
          for (let pass = 0; pass < 3; pass++) {
            let changed = false;
            for (let i = 0; i < fit.length; i++) {
              if (i === pinned) continue;
              const before = fit[i],
                others = fit.filter((_, n) => n !== i);
              let best = before,
                bestScore = score([...others, before]);
              for (const candidate of group[i]) {
                const value = score([...others, candidate]);
                if (value > bestScore + 1e-8) {
                  best = candidate;
                  bestScore = value;
                }
              }
              fit[i] = best;
              if (best !== before) changed = true;
            }
            if (!changed) break;
          }
          const ids = fit.flatMap((x) => x.ids);
          gears.set(ids.join(), ids);
          return fit;
        }
        const base = improve(group.map((g) => g[0]));
        for (let n = 0; n < group.length; n++) {
          const others = base.filter((_, j) => j !== n);
          const sorted = group[n]
            .slice()
            .sort((a, b) => score([...others, b]) - score([...others, a]));
          const candidates = new Set(sorted.slice(0, 4));
          // Preserve both 2H and main hand + shield/focus among weapon candidates.
          if (n === 12)
            for (const handed of [true, false]) {
              const o = sorted.find((x) => !!x.ids[1] === handed);
              if (o) candidates.add(o);
            }
          for (const id of wanted) {
            const o = sorted.find((x) => x.ids.includes(id));
            if (o) candidates.add(o);
          }
          for (const o of candidates) {
            const fit = base.slice();
            fit[n] = o;
            improve(fit, n);
          }
        }
        {
          for (const set of spec === "enhancement" ? [1, 123, 1679] : [1679]) {
            const fit = base.slice();
            for (let n = 0; n < 10; n++) {
              const piece = group[n].find(
                (o) => byID.get(o.ids[0])?.set === set,
              );
              if (piece) fit[n] = piece;
            }
            const ids = fit.flatMap((o) => o.ids);
            gears.set(ids.join(), ids);
          }
        }
      }
  return [...gears.values()];
}
