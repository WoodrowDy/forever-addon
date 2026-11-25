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
    return a.score>b.score
end
function ns.plan(class,role,p,picker,preview)
    local left,right
    local target=ns.roles[role][2] and (p.target or ns.roles[role][2]) or 0
    for _,row in ipairs(ns.planRows(role)) do
        if (not p.pinSlot or row.gear[p.pinSlot]==p.pin) and matches(row.gear,p.pin) and not (p.noRep and row.rep) and not (p.noTier and row.tier) then
            local hit,other=0,0
            for _,id in ipairs(row.gear) do hit=hit+(ns.itemHit[id] or 0) end
            for _,slot in ipairs(armorSlots) do
                if ns.data.items[row.gear[slot]][3]~=class.armor then other=other+1 end
            end
            local score=row.perf
            if class.token=="DRUID" and ns.roles[role][2] then
                score=score-math.max(0,hit-target*10)*ns.hitWeight[role]
            end
            local result={row=row,score=score,hit=hit/10,short=math.max(0,target-hit/10),other=other}
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
    if not from or not to or not ns.data.sets[role] then return end
    if not measured[role] then
        local map={}
        for _,r in ipairs(ns.data.sets[role]) do map[table.concat(r.gear,",")]=r.perf end
        measured[role]=map
    end
    local gear={unpack(from.gear)}
    gear[slot]=to
    local score=measured[role][table.concat(gear,",")]
    if score then return score-from.perf end
end
