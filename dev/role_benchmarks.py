"""Measure druid finalists with the same revision as the equipment database."""
import concurrent.futures
import json
import math
from pathlib import Path
import subprocess

TALENTS = {'balance':'5232220115501351--5053','cat':'050021-53200032123012125001-055',
           'bear':'050022-5023030212310112501-055','druidHeal':''}
SPECS = {'balance':('balance','balanceDruid'),'cat':('feralcat','feralCatDruid'),
         'bear':('feralbear','feralBearDruid'),'druidHeal':('restoration','restorationDruid')}
BEAR_ITERATIONS = 256

def shortlist(states):
    # Retain EP leaders under every whole-percent gear target and material count.
    groups={}
    for (rating,other),(ep,gear) in states.items():
        groups.setdefault(other,[]).append((rating,ep,gear))
    selected=set()
    for group in groups.values():
        for target in range(0,max(r[0] for r in group)+10,10):
            top=sorted(group,key=lambda r:(max(0,target-r[0]),-r[1],r[2]))
            selected.update(r[2] for r in top[:2])
    return sorted(selected)

def measure(checkout, helper, role, gears, dps_iterations, seed=251125):
    folder,spec=SPECS[role]
    profile=json.loads((checkout/'ui/specs/shaman/elemental/builds/default.build.json').read_text())
    encounter=profile['encounter']
    is_dps = role in ("balance", "cat")
    encounter.update(duration=300 if is_dps else 180, durationVariation=60 if is_dps else 0)
    player={'race':'RaceTauren','class':'ClassDruid','talentsString':TALENTS[role],
            spec:{'options':{'classOptions':{}}},'name':'BiSFit'}
    raid={'parties':[{'players':[player]}]}
    if role!='druidHeal':
        apl='default' if role=='balance' else 'adaptive'
        player['rotation']=json.loads((checkout/f'ui/specs/druid/{folder}/apls/{apl}.apl.json').read_text())
        for key in ('priorityList','prepullActions'):
            player['rotation'][key]=[a for a in player['rotation'].get(key,[]) if 'itemSwap' not in a.get('action',{})]
    if role=='bear':
        raid['tanks']=[{'type':'Player','index':0}]
        player['healingModel']={'burstWindow':6,'hps':5000,'cadenceSeconds':2}
        encounter['targets'][0]['tankIndex']=0
    iterations = {'bear': BEAR_ITERATIONS, 'druidHeal': 0}.get(role, dps_iterations)
    req={'raid':raid,'encounter':encounter,'simOptions':{'iterations':iterations,'randomSeed':str(seed)}}
    inputs=[]
    for gear in gears:
        player['equipment']={'items':[{'id':i} if i else {} for i in gear]}
        inputs.append(json.dumps(req))
    def run(batch):
        proc=subprocess.run([str(helper)],input='\n'.join(batch)+'\n',text=True,capture_output=True)
        if proc.returncode: raise ValueError(proc.stderr[-3000:])
        result=[json.loads(line) for line in proc.stdout.splitlines()]
        if len(result)!=len(batch): raise ValueError("Incomplete benchmark")
        return result
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        results=[m for batch in ex.map(run,[inputs[i:i+24] for i in range(0,len(inputs),24)]) for m in batch]
    metrics={}
    for gear,m in zip(gears,results):
        if role=='bear':
            record={'dtps':m['dtps'],'tmi':m['tmi']}
        elif role=='druidHeal':
            stats,pseudo=m['stats'],m['pseudo']
            heal=(1946.4+stats[4])*(1+max(0,min(100,pseudo[15]))/200)
            record={'heal':heal,'cast':max(1,3.5/(1+pseudo[22]/100)),'mana':stats[30],'mp5':stats[31]}
        else:record={'dps':m['mean'],'se':m['sd']/math.sqrt(dps_iterations)}
        if not all(math.isfinite(x) and x>=0 for x in record.values()) or not next(iter(record.values())) or (role=="bear" and record["tmi"]<=0):
            raise ValueError(f"Invalid {role} benchmark {record}")
        metrics[gear]={k:round(v,4) for k,v in record.items()}
    return metrics
