local _, ns = ...
local armorSlots = {1,3,5,6,7,8,9,10}
local function matches(gear, pin)
    if not pin then return true end
    for _,id in ipairs(gear) do if id==pin then return true end end
    return false
end
function ns.planRows(role)
    return ns.data.sets[role] or ns.druidSets[role]
end
local function better(a,b,mode)
    if not b then return true end
    if a.short~=b.short then return a.short<b.short end
    if mode=="prefer" and a.other~=b.other then return a.other<b.other end
    if a.score==b.score and a.dtps then return a.dtps<b.dtps end
    if a.dtps then return a.score<b.score end
    return a.score>b.score
end
-- Continuous static MP5, full mana at pull, no overheal or consumables.
-- Stop casting until enough mana is available; only completed casts heal.
function ns.healingBudget(heal, cast, cost, maximum, mp5)
    local elapsed,mana,count=0,maximum,0
    local regen=mp5/5
    while mana>=cost or (regen>0 and maximum>=cost) do
        local wait=mana>=cost and 0 or (cost-mana)/regen
        if elapsed+wait+cast>180 then break end
        mana=math.min(maximum,mana+wait*regen)-cost
        elapsed=elapsed+wait+cast
        mana=math.min(maximum,mana+cast*regen)
        count=count+1
    end
    return count*heal/180,math.min(maximum,mana+(180-elapsed)*regen)
end
local healCache={}
local function healing(role,row)
    if not healCache[row] then
        local heal,cast,cost,mana,mp5
        if role=="restoration" then
            heal,cast,cost,mana,mp5=row.heal,row.heal/row.perf,361,row.stats[11],row.stats[10]
        else
            local b=row.bench
            heal,cast,cost,mana,mp5=b.heal,b.cast,755,b.mana,b.mp5
        end
        local hps,ending=ns.healingBudget(heal,cast,cost,mana,mp5)
        healCache[row]={hps=hps,ending=ending,mp5=mp5}
    end
    return healCache[row]
end
local function roleScore(role,row)
    if role=="restoration" or role=="druidHeal" then return healing(role,row).hps end
    if role=="bear" then return row.bench.tmi end
    return row.bench and row.bench.dps or row.perf
end
function ns.plan(class,role,p,picker,preview)
    local left,right
    local target=ns.roles[role][2] and (p.target or (role=="bear" and 0 or ns.roles[role][2])) or 0
    for _,row in ipairs(ns.planRows(role)) do
        if (not p.pinSlot or row.gear[p.pinSlot]==p.pin) and matches(row.gear,p.pin) and not (p.noRep and row.rep) and not (p.noTier and row.tier) then
            local hit,other=0,0
            for _,id in ipairs(row.gear) do hit=hit+(ns.itemHit[id] or 0) end
            for _,slot in ipairs(armorSlots) do
                if ns.data.items[row.gear[slot]][3]~=class.armor then other=other+1 end
            end
            local result={row=row,score=roleScore(role,row),hit=hit/10,short=math.max(0,target-hit/10),other=other}
            if role=="bear" then result.dtps=row.bench.dtps end
            if role=="restoration" or role=="druidHeal" then result.healing=healing(role,row) end
            local leftOK=other==0 or p.prefer
            if picker and (picker.side==2 or leftOK) then
                local id=row.gear[picker.slot]
                if id>0 then picker.ids[id]=true end
            end
            local selected=not preview or row.gear[preview.slot]==preview.id
            if (not preview or preview.side~=2 or selected) and better(result,right,"mixed") then right=result end
            if leftOK and (not preview or preview.side~=1 or selected) and better(result,left,p.prefer and "prefer" or "strict") then left=result end
        end
    end
    return left,right
end
-- A farming step changes exactly one equipped armor piece; all other slots stay fixed.
function ns.oneArmorUpgrade(class,role,p,base)
    if not base or base.other~=0 or base.short>0 then return end
    local best,slotIndex
    for _,row in ipairs(ns.planRows(role)) do
        if roleScore(role,row)>base.score and (not best or roleScore(role,row)>best.score)
            and not (p.noRep and row.rep or p.noTier and row.tier) then
            local changed
            for i,id in ipairs(row.gear) do
                if id~=base.row.gear[i] then
                    if changed then changed=nil;break end
                    changed=i
                end
            end
            if changed and changed~=p.pinSlot and matches(row.gear,p.pin) then
                for _,slot in ipairs(armorSlots) do
                    if changed==slot then
                        local id=row.gear[slot]
                        local hit=base.hit*10-(ns.itemHit[base.row.gear[slot]] or 0)+(ns.itemHit[id] or 0)
                        if ns.data.items[id][3]~=class.armor and hit+0.00001>=10*(p.target or 0) then
                            best={score=roleScore(role,row),item=id};slotIndex=slot
                        end
                        break
                    end
                end
            end
        end
    end
    return best,slotIndex
end
function ns.maxGearHit(role,p,strict)
    local shaman=role=="enhancement" or role=="elemental"
    local key=table.concat({role,strict and 1 or 0,shaman and p.noRep and 1 or 0,shaman and p.noTier and 1 or 0},"/")
    local caps=ns.hitCaps and ns.hitCaps[key]
    if not caps then return end
    if not p.pin then return caps.max/10 end
    local best
    for slot=1,17 do
        if not p.pinSlot or slot==p.pinSlot then
            local hit=caps[slot][p.pin]
            if hit and (not best or hit>best) then best=hit end
        end
    end
    if best then return best/10 end
end
function ns.planStatus(result,strict)
    if not result then return "조건에 맞는 후보 없음" end
    if result.short>0 then
        return (strict and "목표 미달 (없어 돌아가)" or "목표 미달")..string.format(" · %.1f%%p 부족",result.short)
    end
    if result.other>0 then return result.other.."부위 혼합 · 목표 달성" end
    return "목표 달성"
end

function ns.currentTalentRank(class)
    if not UnitClass or select(2,UnitClass("player"))~=class.token then return end
    if not GetNumTalents or not GetTalentInfo then return end
    local t=class.talent
    local localized=C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(t.spell)
    local count=GetNumTalents(t.tree)
    for index=1,count or 0 do
        local name,_,tier,column,rank,maxRank=GetTalentInfo(t.tree,index)
        if tier==t.tier and column==t.column and maxRank==t.max
            and (name==localized or name==t.name) then return rank end
    end
end

-- Only report a swap measurement when the whole resulting set was benchmarked.
local measured={}
function ns.swapDelta(role,from,slot,to)
    if not from or not to or not ns.planRows(role) then return end
    if not measured[role] then
        local map={}
        for _,r in ipairs(ns.planRows(role)) do map[table.concat(r.gear,",")]=roleScore(role,r) end
        measured[role]=map
    end
    local gear={unpack(from.gear)}
    gear[slot]=to
    local score=measured[role][table.concat(gear,",")]
    if score then return score-roleScore(role,from) end
end
