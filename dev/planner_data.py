"""Build item EP and a bounded druid set catalog from the same upstream DB as Data.lua."""
import itertools
import subprocess
import json
import re
import sys
from pathlib import Path

from role_benchmarks import measure, shortlist

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
    'druidHeal': {4:1,31:1.86,3:.77}, # 180s reference item weights; final ranking uses sustained healing
}
# Retain only defensive components of the upstream bear scoring profile.
weights['bear']={k:v for k,v in weights['bear'].items() if k in (1,2,22,25,27,28,29,38)}
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
    return sum(w.get(int(k),0)*v for k,v in stats(i).items()) + dps*{'enhancement':14.18,'cat':2.14201}.get(role,0)

def lua(v):
    if isinstance(v,dict):
        return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,(tuple,list)):return '{'+','.join(map(lua,v))+'}'
    return json.dumps(v,ensure_ascii=False)

out = ['local _, ns = ...','ns.itemHit = {}','ns.itemEP = {}','ns.druidSets = {}']
audit = json.loads(subprocess.check_output(
    ['node', str(root/'dev/druid_catalog.ts'), sys.argv[1]], text=True))
catalog = {item['id']: item for item in audit['items']}
ids = shared | set(catalog)
for role,base in zip(roles,bases):
    for slot,i in enumerate(base,1):
        if i and i not in catalog:
            print(f"WOWF {role} slot={slot} id={i}: {audit['excluded'].get(str(i),'원본 DB 미수록')}")
print(f"드루이드 공통 기준 통과: {len(catalog)}개")
out.append('ns.gearStats='+lua({i:{int(k):v for k,v in stats(i).items()} for i in sorted(ids)}))
out.append('ns.hitWeight='+lua({role:w.get(17,0) for role,w in weights.items()}))
for i in sorted(ids):
    out.append(f'ns.itemHit[{i}]={hit(i)}')
for role in weights:
    out.append('ns.itemEP.'+role+'='+lua({i:round(ep(role,i),4) for i in sorted(ids)}))
by_type = {t:sorted(i for i,v in catalog.items() if v['type']==t) for t in range(1,15)}
# Clusters must cover every shared unique-equipped category.
category_types={}
for v in catalog.values():
    if v['category']:
        category_types.setdefault(v['category'],set()).add(v['type'])
if any(len(types)>1 for types in category_types.values()):
    raise ValueError("Cross-slot equipment category needs joint validation")

def compatible(a,b):
    if not b: return True
    return not ((a==b and catalog[a]['unique']) or
                (catalog[a]['category'] and catalog[a]['category']==catalog[b]['category']) or
                {a,b}=={13965,13968})

def pairs(group):
    if group in (11,12):
        return [(a,b) for a,b in itertools.combinations_with_replacement(by_type[group],2)
                if compatible(a,b)]
    if group==13:
        offhands=[i for i in by_type[13] if catalog[i]['weapon']==5]
        return [(a,b) for a in by_type[13] if catalog[a]['hand'] in (1,2,4)
                and catalog[a]['weapon']!=5
                for b in ([0] if catalog[a]['hand']==4 else [0,*offhands]) if compatible(a,b)]
    return [(i,) for i in by_type[group]]

for role,base in zip(roles,bases):
    states = {(0,0):(0,())}
    for group in range(1,15):
        slot=group-1
        pool=pairs(group)
        # A reference item can break an EP tie only after passing the catalog rules.
        if group==14:
            pool.sort(key=lambda ids: ids[0]!=base[16])
        # For identical rating and material count only the best group can win.
        options={}
        for group_ids in pool:
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
    candidates=shortlist(states)
    metrics=measure(Path(sys.argv[1]).resolve().parents[2], Path(sys.argv[2]).resolve(),role,candidates)
    print(role,len(metrics),flush=True)
    # Ship only benchmarked finalists.
    rows=['{gear='+lua(g)+',perf='+str(round(sum(ep(role,i) for i in g),4))+',bench='+lua(metrics[g])+'}' for g in sorted(candidates,key=lambda g:(-sum(ep(role,i) for i in g),g))]
    out.append('ns.druidSets.'+role+'={\n'+',\n'.join(rows)+'\n}')
for i in sorted(ids-shared):
    x=db[i]
    detail=catalog[i]['source']
    out.append(f'ns.data.items[{i}]='+lua([x['name'], detail,x.get('armorType',0),x['quality'],x.get('icon','')]))
(root/'PlannerData.lua').write_text('\n'.join(out)+'\n')
