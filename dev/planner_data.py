"""Build item EP and a bounded druid set catalog from the same upstream DB as Data.lua."""
import json
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
db = {i['id']: i for i in json.loads(Path(sys.argv[1]).read_text())['items']}
data = (root/'Data.lua').read_text()
shared = set(map(int, re.findall(r'^\[(\d+)\]=', data, re.M)))
roles = ['balance', 'cat', 'bear', 'druidHeal']
templates = (root/'Classes/Druid.lua').read_text().split('ns.druidItemIDs = {')[1].split('\n}')[0]
bases = [list(map(int, row.split(','))) for row in re.findall(r'\{([\d, ]+)\}', templates)]
armor = {0, 2, 4, 5, 6, 7, 8, 9}
weights = {
    'balance': {3:.2,5:1,6:.68,10:.32,17:1.45,18:.76,19:.95},
    'cat': {0:.594218,1:.654662,14:.243789,16:.243139,17:.521158,18:.505716,19:.393069,20:.074215,21:.490405,37:1.863062},
    'bear': {0:.48605,1:.433479,2:1.002875,14:.220932,16:.220932,17:.687945,18:.363262,19:.35813,20:.082629,21:1.775974,22:.875831,25:.107395,27:.174376,28:.174376,29:.077171,37:1.366686,38:.036912},
    'druidHeal': {4:1}, # transparent healing-power-only baseline
}
search = (root/'dev/search.ts').read_text().split('const emphasis')[0]
for role, body in re.findall(r'(enhancement|elemental|restoration):\s*\{([^}]+)\}', search):
    weights[role] = {int(k):float(v) for k,v in re.findall(r'(\d+):\s*([\d.]+)',body)}

def stats(i):
    return db[i]['scalingOptions']['0'].get('stats',{}) if i else {}

def hit(i):
    return stats(i).get('17',0)

def ep(role,i):
    if not i: return 0
    w = weights[role]
    dps = db[i]['scalingOptions']['0'].get('unroundedDps',0)
    return sum(w.get(int(k),0)*v for k,v in stats(i).items()) + dps*{'enhancement':14.18,'cat':2.14201,'bear':3.09305}.get(role,0)

def lua(v):
    if isinstance(v,dict):
        return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,(tuple,list)):return '{'+','.join(map(lua,v))+'}'
    return json.dumps(v,ensure_ascii=False)

out = ['local _, ns = ...','ns.itemHit = {}','ns.itemEP = {}','ns.druidSets = {}']
ids = shared.union(*bases)-{0}
out.append('ns.gearStats='+lua({i:{int(k):v for k,v in stats(i).items()} for i in sorted(ids)}))
out.append('ns.hitWeight='+lua({role:w.get(17,0) for role,w in weights.items()}))
for i in sorted(ids):
    out.append(f'ns.itemHit[{i}]={hit(i)}')
for role in weights:
    out.append('ns.itemEP.'+role+'='+lua({i:round(ep(role,i),4) for i in sorted(ids)}))
common = [i for i in sorted(shared) if 11 in db[i].get('classAllowlist',[11]) and not db[i].get('limitCategory') and not db[i].get('factionRestriction')]
# Compare independent equipment groups. Keep ring, trinket and weapon pairs
# intact so a recombination never splits a two-hander or duplicates a unique.
shaman_gears = [tuple(map(int,line.split(','))) for line in re.findall(r'gear=\{([\d,]+)\}',data)]
common_set=set(common)
for role,base in zip(roles,bases):
    states = {(0,0):(0,())}
    groups=[(i,) for i in range(10)]+[(10,11),(12,13),(14,15),(16,)]
    for group in groups:
        slot=group[0]
        pool={tuple(base[i] for i in group)}
        if slot < 10:
            pool.update((i,) for i in common if db[i]['type']==slot+1 and
                        (slot not in armor or db[i].get('armorType') in (1,2)))
        elif slot in (10,12,14):
            for g in shaman_gears:
                pair=tuple(g[i] for i in group)
                if not all(i==0 or i in common_set for i in pair):continue
                if slot==14 and (db[pair[0]].get('weaponType') not in (2,3,4,8)
                                 or (pair[1] and db[pair[1]].get('weaponType')!=5)):continue
                pool.add(pair)
        # For identical rating and material count only the best group can win.
        options={}
        for group_ids in sorted(pool):
            wrong=int(slot in armor and db[group_ids[0]].get('armorType')!=2)
            key=(sum(hit(i) for i in group_ids),wrong)
            score=sum(ep(role,i) for i in group_ids)
            if key not in options or options[key][0]<score:options[key]=(score,group_ids)
        next_states={}
        for (h1,n1),(points,group_ids) in options.items():
            for (h,n),(score,gear) in states.items():
                key=(h+h1,n+n1)
                if key not in next_states or next_states[key][0]<score+points:
                    next_states[key]=(score+points,gear+group_ids)
        states=next_states
    candidates={gear for _,gear in states.values()}|{tuple(base)}
    # Keep the best candidate for each rating, plus the source set for pinning.
    rows=['{gear='+lua(g)+',perf='+str(round(sum(ep(role,i) for i in g),4))+'}' for g in sorted(candidates,key=lambda g:(-sum(ep(role,i) for i in g),g))]
    out.append('ns.druidSets.'+role+'={\n'+',\n'.join(rows)+'\n}')
for i in sorted(ids-shared):
    x=db[i]
    sources=x.get('sources',[])
    detail=next((s['soldBy'].get('npcName') for s in sources if s.get('soldBy',{}).get('npcName')),None)
    out.append(f'ns.data.items[{i}]='+lua([x['name'], detail or 'WOWF.IO · 역할별 추천 목록',x.get('armorType',0),x['quality'],x.get('icon','')]))
(root/'PlannerData.lua').write_text('\n'.join(out)+'\n')
