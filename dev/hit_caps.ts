// Build maximum equipment hit from legal slot groups, independent of the DPS shortlist.
import fs from "node:fs";
import { armorSlots, catalog, type Item } from "./catalog.ts";

const db = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const output = ["local _,ns=...", "ns.hitCaps={}"];
for (const [role, classId, tierStart] of [
  ["enhancement",7,227017], ["elemental",7,227001], ["cat",11,0], ["balance",11,0],
] as const) {
  const items = catalog(db, classId);
  const categorySlot = new Map<number,number>();
  for (const item of items) {
    if (!item.category) continue;
    if (categorySlot.has(item.category) && categorySlot.get(item.category)!==item.type)
      throw Error("Cross-slot unique category requires joint optimization");
    categorySlot.set(item.category,item.type);
  }
  for (const strict of [false,true]) for (const noRep of (classId===7?[false,true]:[false]))
    for (const noTier of (classId===7?[false,true]:[false])) {
      const pool=items.filter(i => !(noRep && i.rep) &&
        !(classId===7 && i.set===1679 && (noTier || i.id<tierStart || i.id>=tierStart+8)) &&
        !(strict && armorSlots.includes(i.type-1) && i.armor!==(classId===7?3:2)));
      const maxima = new Map<number,number>();
      const slots: Map<number,number>[] = Array.from({length:17},()=>new Map());
      const groupForSlot: number[]=[];
      function option(group:number, firstSlot:number, ids: (Item|undefined)[]) {
        const h=ids.reduce((n,i)=>n+(i?.rating[17]??0),0);
        maxima.set(group,Math.max(maxima.get(group)??0,h));
        ids.forEach((i,k)=>{
          const slot=firstSlot+k;
          groupForSlot[slot]=group;
          if(i) slots[slot].set(i.id,Math.max(slots[slot].get(i.id)??0,h));
        });
      }
      function compatible(a:Item,b:Item) {
        return !(a.id===b.id && a.unique) && !(a.category && a.category===b.category)
          && !(a.id!==b.id && [13965,13968].includes(a.id) && [13965,13968].includes(b.id));
      }
      for (let type=1;type<=14;type++) {
        const group=pool.filter(i=>i.type===type);
        if(type===11 || type===12) {
          for(const a of group) for(const b of group)
            if(compatible(a,b)) option(type,type===11?10:12,[a,b]);
        } else if(type===13) {
          const offTypes=classId===7?[5,7]:[5];
          for(const a of group.filter(i=>[1,2,4].includes(i.hand) && !offTypes.includes(i.weapon))) {
            if(a.hand===4 || classId===11) option(type,14,[a,undefined]);
            if(a.hand!==4) for(const b of group.filter(i=>offTypes.includes(i.weapon)))
              if(compatible(a,b)) option(type,14,[a,b]);
          }
        } else for(const a of group) option(type,type===14?16:type-1,[a]);
      }
      if(maxima.size!==14) throw Error("Incomplete gear pool for "+role);
      const max=[...maxima.values()].reduce((a,b)=>a+b,0);
      const tables=slots.map((slot,index)=>"{"+[...slot].map(([id,h])=>
        "["+id+"]="+(max-maxima.get(groupForSlot[index])!+h)).join(",")+"}");
      output.push('ns.hitCaps["'+[role,+strict,+noRep,+noTier].join("/")+'"]={max='+max+','+tables.join(",")+'}');
    }
}
fs.writeFileSync("HitCaps.lua.tmp", output.join("\n")+"\n");
fs.renameSync("HitCaps.lua.tmp","HitCaps.lua");
