local _, ns = ...
ns.specNames = { enhancement="고양", elemental="정기", restoration="복원" }
ns.slotNames = {"머리","목","어깨","등","가슴","손목","손","허리","다리","발","반지 1","반지 2","장신구 1","장신구 2","주 무기","보조 장비","토템"}
local armor = {[1]=true,[3]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true}
local statNames = {"방어도","힘","민첩성","체력","지능","정신력","전투력","주문 피해","치유력","5초당 마나","최대 마나","근접 적중","주문 적중","숙련","근접 치명타","주문 치명타","자연 피해","화염 피해","주문 가속"}
ns.statNames = statNames
ns.statOrders = {
 enhancement={1,2,3,4,5,7,8,12,13,14,15,16},
 elemental={1,4,5,8,17,18,13,16,19,11,10},
 restoration={1,4,5,6,9,16,19,11,10},
}
function ns.isPercent(i) return (i>=12 and i<=16) or i==19 end
function ns.newState(saved)
    local state=type(saved)=="table" and saved or {}
    if not ns.specNames[state.spec] then state.spec="enhancement" end
    state.noRep=state.noRep==true
    state.noTier=state.noTier==true
    if type(state.pin)~="number" or not ns.data.items[state.pin] then state.pin=nil end
    if state.pin then
        local _,mixed=ns.compare(state)
        if not mixed then state.pin=nil end
    end
    return state
end
local function contains(gear,id)
    if not id then return true end
    for _,item in ipairs(gear) do if item==id then return true end end
    return false
end
function ns.compare(state)
    local mail,mixed
    for _,row in ipairs(ns.data.sets[state.spec]) do
        if (not state.noTier or not row.tier) and (not state.noRep or not row.rep) and contains(row.gear,state.pin) then
            mixed=mixed or row
            if row.mail then mail=row; break end
        end
    end
    return mail,mixed
end
function ns.options(state,slot,mailOnly)
    local choices,seen={},{}
    local function add(id)
        if id and id>0 and not seen[id] then choices[#choices+1]=id;seen[id]=true end
    end
    for _,row in ipairs(ns.data.sets[state.spec]) do
        if (not state.noTier or not row.tier) and (not state.noRep or not row.rep) and (not mailOnly or row.mail) then
            add(row.gear[slot])
            if slot==11 or slot==12 then add(row.gear[23-slot]) end
            if slot==13 or slot==14 then add(row.gear[27-slot]) end
        end
    end
    return choices
end
function ns.material(slot,id)
    if not armor[slot] or not ns.data.items[id] then return "" end
    return ({[1]="천",[2]="가죽",[3]="사슬"})[ns.data.items[id][3]] or ""
end
local requested={}
function ns.itemName(id)
    local item=ns.data.items[id]
    if not item then return "—" end
    if C_Item and C_Item.GetItemNameByID then
        local name=C_Item.GetItemNameByID(id)
        if name then return name end
        if not requested[id] and C_Item.RequestLoadItemDataByID then
            requested[id]=true;C_Item.RequestLoadItemDataByID(id)
        end
    end
    return item[1]
end
function ns.difference(mail,mixed)
    if not (mail and mixed) or mixed.perf<=0 then return nil end
    return mail.perf-mixed.perf,100*(mail.perf/mixed.perf-1)
end
