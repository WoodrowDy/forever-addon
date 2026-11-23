// Node 24+, no npm packages. Run after building the WoWSims measurement helper.
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execFileSync, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { catalog, armorSlots, validateGear } from "./catalog.ts";
import { search, specs, type Spec } from "./search.ts";
const [checkout, helper, suppliedRevision] = process.argv.slice(2);
if (!checkout || !helper)
  throw Error("Usage: node dev/refresh.ts WOWSIMS_CHECKOUT MEASURE [REVISION]");
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const json = (file: string) =>
  JSON.parse(fs.readFileSync(path.join(checkout, file), "utf8"));
const revision =
  suppliedRevision ||
  execFileSync("git", ["-C", checkout, "rev-parse", "HEAD"], {
    encoding: "utf8",
  }).trim();
if (!/^[a-f0-9]{40}$/.test(revision))
  throw Error("A complete source revision is required");
const items = catalog(json("assets/database/db.json"));
const byId = new Map(items.map((i) => [i.id, i]));
const iterations = 1600;
const profiles: any = {},
  builds: any = {};
for (const spec of specs) {
  const profile = json(
    "ui/specs/shaman/" +
      (spec === "restoration" ? "elemental" : spec) +
      "/builds/default.build.json",
  );
  profile.encounter.duration = 180;
  profile.encounter.durationVariation = 0;
  const p = profile.player;
  p.race = "RaceTauren";
  p.equipment = {};
  delete p.itemSwap;
  if (spec === "restoration") {
    delete p.elementalShaman;
    p.restorationShaman = { options: { classOptions: {} } };
    // Only the indicated Restoration tree is needed by the LHW benchmark.
    p.talentsString = "--5530000115513151";
    p.rotation = {};
    p.consumables = {};
    p.buffs = {};
    profile.raidBuffs = {};
    profile.debuffs = {};
  } else {
    p.rotation.priorityList = p.rotation.priorityList.filter(
      (row: any) => !row.action?.itemSwap,
    );
  }
  builds[spec] = p.talentsString;
  profiles[spec] = {
    raid: {
      parties: [{ players: [p], buffs: profile.partyBuffs ?? {} }],
      buffs: profile.raidBuffs ?? {},
      debuffs: profile.debuffs ?? {},
    },
    encounter: profile.encounter,
    type: "SimTypeIndividual",
    simOptions: {
      iterations: spec === "restoration" ? 0 : iterations,
      randomSeed: "251122",
    },
  };
}
const records: { spec: Spec; gear: number[] }[] = specs.flatMap((spec) =>
  search(items, spec).map((gear) => ({ spec, gear })),
);
console.log(
  "Catalog:",
  items.length,
  "sets:",
  Object.fromEntries(
    specs.map((s) => [s, records.filter((r) => r.spec === s).length]),
  ),
);
const bundle: any = {
  date: new Date().toISOString().slice(0, 10),
  revision,
  iterations,
  builds,
  catalogSize: items.length,
  items: {},
  sets: { enhancement: [], elemental: [], restoration: [] },
};
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "shamanfit-"));
const ident = (s: string) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(s);
function toLua(x: any): string {
  if (typeof x === "number") {
    if (!Number.isFinite(x)) throw Error("Non-finite result");
    return String(x);
  }
  if (typeof x === "boolean") return String(x);
  if (typeof x === "string") return JSON.stringify(x);
  if (Array.isArray(x)) return "{" + x.map(toLua).join(",") + "}";
  return (
    "{\n" +
    Object.entries(x)
      .map(([k, v]) => (ident(k) ? k : "[" + Number(k) + "]") + "=" + toLua(v))
      .join(",\n") +
    "\n}"
  );
}
const r2 = (n: number) => Math.round(n * 100) / 100;
async function shard(rows: typeof records, n: number) {
  const input = path.join(scratch, n + ".in"),
    output = path.join(scratch, n + ".out");
  const requests = rows.map(({ spec, gear }) => {
    validateGear(gear, byId);
    const req = profiles[spec];
    req.raid.parties[0].players[0].equipment = {
      items: gear.map((id) => (id ? { id } : {})),
    };
    return JSON.stringify(req);
  });
  fs.writeFileSync(input, requests.join("\n") + "\n");
  const infd = fs.openSync(input, "r"),
    outfd = fs.openSync(output, "w");
  try {
    await new Promise<void>((ok, fail) => {
      const child = spawn(path.resolve(helper), [], {
        stdio: [infd, outfd, "inherit"],
      });
      child.once("error", fail);
      child.once("exit", (code, signal) =>
        code === 0
          ? ok()
          : fail(Error("Measurement failed: " + (signal ?? code))),
      );
    });
  } finally {
    fs.closeSync(infd);
    fs.closeSync(outfd);
  }
  const measured = fs.readFileSync(output, "utf8").trim().split("\n");
  if (measured.length !== rows.length) throw Error("Incomplete batch");
  return measured.map((line, j) => {
    const { spec, gear } = rows[j],
      m = JSON.parse(line),
      s = m.stats,
      p = m.pseudo;
    const loot = gear.filter(Boolean).map((id) => byId.get(id)!);
    const heal =
      (820 + 0.429 * s[4]) *
      1.1 *
      (1 + Math.min(100, Math.max(0, p[15])) / 200);
    const bonuses: string[] = [...(m.sets ?? [])];
    if (loot.filter((i) => i.set === 1).length >= 2)
      bonuses.unshift("검투사 2 · 받는 공포 적중 −8%");
    const hps = heal / Math.max(1, 1.5 / (1 + p[22] / 100));
    const stats = [
      s[27],
      s[0],
      s[1],
      s[2],
      s[3],
      s[13],
      s[14],
      s[5],
      s[4],
      s[31],
      s[30],
      p[12],
      p[13],
      p[27],
      p[14],
      p[15],
      s[10],
      s[7],
      p[22],
    ].map(r2);
    return {
      spec,
      entry: {
        gear,
        mail: armorSlots.every((i) => byId.get(gear[i])?.armor === 3),
        rep: loot.some((i) => i.rep),
        tier: loot.some((i) => i.set === 1679),
        perf: r2(spec === "restoration" ? hps : m.mean),
        se: r2(spec === "restoration" ? 0 : m.sd / Math.sqrt(m.iterations)),
        heal: r2(spec === "restoration" ? heal : 0),
        stats,
        bonuses,
      },
    };
  });
}
try {
  async function evaluate(list: typeof records) {
    if (!list.length) return;
    const shards = Math.min(6, os.availableParallelism(), list.length);
    const batches = await Promise.all(
      Array.from({ length: shards }, (_, n) =>
        shard(
          list.filter((_, i) => i % shards === n),
          n,
        ),
      ),
    );
    for (const { spec, entry } of batches.flat()) bundle.sets[spec].push(entry);
  }
  await evaluate(records);
  // Recombine the strongest measured complete sets, preserving legal weapon and ring pairs.
  const followups: typeof records = [];
  const blocks = Array.from({ length: 10 }, (_, i) => [i]).concat([
    [10, 11],
    [12, 13],
    [14, 15],
    [16],
  ]);
  for (const spec of specs) {
    const prior = bundle.sets[spec]
      .slice()
      .sort((a: any, b: any) => b.perf - a.perf);
    const known = new Set(prior.map((r: any) => r.gear.join(",")));
    for (const mail of [true, false])
      for (const noRep of [true, false])
        for (const noTier of [true, false]) {
          const finalists = prior
            .filter(
              (r: any) =>
                (!mail || r.mail) && (!noRep || !r.rep) && (!noTier || !r.tier),
            )
            .slice(0, 8);
          for (const base of finalists.slice(0, 2))
            for (const donor of finalists)
              for (const slots of blocks) {
                const gear = base.gear.slice();
                for (const i of slots) gear[i] = donor.gear[i];
                const key = gear.join(",");
                if (known.has(key)) continue;
                known.add(key);
                followups.push({ spec, gear });
              }
        }
  }
  // The benchmark gives several relics equal direct healing. Include the Water Shield relic for tie-breaking.
  const healing = [...records, ...followups].filter(
    (r) => r.spec === "restoration",
  );
  const healKeys = new Set(healing.map((r) => r.gear.join(",")));
  for (const r of healing) {
    const gear = r.gear.slice();
    gear[16] = 23200;
    if (byId.has(23200) && !healKeys.has(gear.join(","))) {
      healKeys.add(gear.join(","));
      followups.push({ spec: "restoration", gear });
    }
  }
  console.log("Rechecking", followups.length, "recombined sets.");
  await evaluate(followups);
  records.push(...followups);
  for (const spec of specs) {
    bundle.sets[spec].sort(
      (a: any, b: any) =>
        b.perf - a.perf ||
        (spec === "restoration"
          ? Number(b.gear[16] === 23200) - Number(a.gear[16] === 23200)
          : 0) ||
        a.gear.join().localeCompare(b.gear.join()),
    );
    for (const needMail of [true, false])
      for (const noRep of [true, false])
        if (
          !bundle.sets[spec].some(
            (r: any) =>
              (!needMail || r.mail) && (!noRep || !r.rep) && r.perf > 0,
          )
        )
          throw Error("Missing comparison for " + spec);
  }
  const used = new Set<number>(records.flatMap((r) => r.gear));
  used.delete(0);
  for (const id of used) {
    const x = byId.get(id)!;
    bundle.items[id] = [x.name, x.source, x.armor, x.quality, x.icon];
  }
  const data = "local _, ns = ...\nns.data = " + toLua(bundle) + "\n";
  fs.writeFileSync(path.join(root, "Data.lua.tmp"), data);
  fs.renameSync(path.join(root, "Data.lua.tmp"), path.join(root, "Data.lua"));
  console.log(
    "Wrote Data.lua",
    data.length,
    "characters,",
    used.size,
    "items in compared sets.",
  );
} finally {
  fs.rmSync(scratch, { recursive: true, force: true });
}
