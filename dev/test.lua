-- Run at the addon repository root: lua5.1 dev/test.lua
local ns={}
local function loadAddon(name) assert(loadfile(name..".lua"))("BiSFit",ns) end
loadAddon("Data");loadAddon("Compare")
local d=ns.data
assert(d.items[277117][2]:find("그리즐"));assert(d.items[11726][2]:find("고로쉬"))
local referenceFound = false
for _, row in ipairs(d.sets.enhancement) do
    local gear = row.gear
    if gear[1]==20134 and gear[2]==22150 and gear[3]==14503 and gear[5]==11726
        and gear[7]==14615 and gear[8]==14614 and gear[9]==14612 and gear[10]==14616
        and gear[13]==272437 and gear[14]==11815 and gear[15]==280056 then
        referenceFound = true
        break
    end
end
assert(referenceFound, "missing measured WoWF reference variant")
local armor={1,3,5,6,7,8,9,10}
assert(not d.items[279260],"craft locked behind an unreleased raid material")
local totals=0
for spec,rows in pairs(d.sets) do
    assert(ns.specNames[spec] and #rows>0)
    local previous=math.huge
    local seen={}
    for _,r in ipairs(rows) do
        totals=totals+1;assert(r.perf>0 and r.perf<=previous);previous=r.perf
        assert(#r.gear==17 and #r.stats==19 and r.se>=0)
        local key=table.concat(r.gear,",");assert(not seen[key],"duplicate set");seen[key]=true
        local mail=true
        for _,slot in ipairs(armor) do if d.items[r.gear[slot]][3]~=3 then mail=false end end
        assert(mail==r.mail)
        for i,id in ipairs(r.gear) do assert(d.items[id] or (i==16 and id==0),"missing item") end
        if spec=="restoration" then assert(r.heal>0 and r.se==0) else assert(r.heal==0 and r.se>0) end
    end
    for _,noRep in ipairs({false,true}) do
      for _,noTier in ipairs({false,true}) do
        local state=ns.newState({spec=spec,noRep=noRep,noTier=noTier})
        local m,x=ns.compare(state)
        assert(m and x and m.mail and x.perf>=m.perf)
        if noRep then assert(not m.rep and not x.rep) end
        if noTier then assert(not m.tier and not x.tier) end
        for slot=1,17 do
            for _,id in ipairs(ns.options(state,slot,true)) do
                state.pin=id;m,x=ns.compare(state)
                assert(m and x,"missing pinned comparison")
                local found=false
                for _,g in ipairs(m.gear) do if g==id then found=true end end
                assert(found)
            end
        end
      end
    end
end
local mail,mix=ns.compare({spec="enhancement",pin=14503})
assert(not mail and mix,"leather pin should only match mixed gear")
assert(ns.newState({spec="priest",pin=-7}).spec=="enhancement")
assert(ns.newState({spec="priest",pin=-7}).pin==nil)
assert(ns.difference(nil,mix)==nil)
local same,percent=ns.difference(mix,mix);assert(same==0 and percent==0)

-- Smoke the full slash-command/UI path using frame doubles. A client test is separate.
local nodes,events={},{}
local blank=function() end
local methods={}
function methods:SetScript(key,f) self.hooks[key]=f end
function methods:RegisterEvent(key) events[key]=self end
function methods:SetText(text) self.text=text end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:GetWidth() return self.w or 1200 end
function methods:GetHeight() return self.h or 800 end
function methods:GetFrameLevel() return 5 end
function methods:Show() self.visible=true end
function methods:Hide() self.visible=false;if self.hooks.OnHide then self.hooks.OnHide(self) end end
function methods:IsShown() return self.visible==true end
local function new(kind,name)
    local t=setmetatable({kind=kind,hooks={}}, {__index=function(_,k) return methods[k] or (k:match("^%u") and blank) end})
    nodes[#nodes+1]=t;if name then _G[name]=t end;return t
end
function methods:CreateTexture() return new("Texture") end
function methods:CreateFontString() return new("FontString") end
CreateFrame=new;UISpecialFrames={};SlashCmdList={};UIParent=new("Frame");GameTooltip=new("Frame")
C_Timer={After=function(_,f) f() end}
GetBuildInfo=function() return "1.60.1","test" end
if not unpack then unpack=table.unpack end
loadAddon("Classes/Shaman");loadAddon("Classes/Druid")
C_Item={GetItemIconByID=function(id) return id end}
loadAddon("PlannerData");loadAddon("HitCaps");loadAddon("ConfirmedDPS")
assert(ns.druidIterations.dps == d.iterations and ns.druidIterations.bear > 0)
loadAddon("Planner");loadAddon("PlannerWindow")
function methods:GetText() return self.text end
for _,class in ipairs(ns.classes) do
    for _,role in ipairs(class.roles) do
        local strict,mixed=ns.plan(class,role,{target=0})
        assert(strict and strict.other==0 and mixed)
        local left,right=ns.plan(class,role,{target=100,prefer=true})
        assert(left and right);if ns.roles[role][2] then assert(left.hit==right.hit) end
        if ns.roles[role][2] then assert(ns.planStatus(left):find("목표 미달성")) end
        local pinned=select(2,ns.plan(class,role,{target=3,pin=mixed.row.gear[1]}))
        assert(pinned and pinned.row.gear[1]==mixed.row.gear[1])
    end
end
local old=ns.druidSets.cat
local leather,mixed=ns.plan(ns.classes[2],"cat",{target=100})
local preferred=ns.plan(ns.classes[2],"cat",{target=mixed.hit,prefer=true})
for _,row in ipairs(old) do
    local rating,other=0,0
    for _,id in ipairs(row.gear) do rating=rating+(ns.itemHit[id] or 0) end
    for _,slot in ipairs(armor) do if ns.data.items[row.gear[slot]][3]~=2 then other=other+1 end end
    if rating/10>=mixed.hit then assert(other>=preferred.other) end
end
assert(ns.planStatus(nil,true)=="조건에 맞는 후보 없음")
SlashCmdList.BISFITPLAN();assert(BiSFitPlanner:IsShown())
local function plannerClick(label)
    for _,b in ipairs(nodes) do
        if b.kind=="Button" and b.text==label then b.hooks.OnClick(b);return end
    end
    error("planner control missing: "..label)
end
plannerClick("드루이드");plannerClick("야성 · 곰")
assert(BiSFitCharacter.profiles.bear.prefer)
plannerClick("가죽 우선");assert(BiSFitCharacter.profiles.bear.prefer==false);plannerClick("가죽만")
assert(BiSFitCharacter.profiles.bear.prefer)
plannerClick("주술사");plannerClick("드루이드")
assert(BiSFitCharacter.lastRole[2]=="bear")
SlashCmdList.BISFITPLAN();assert(not BiSFitPlanner:IsShown())
print("OK: seven planner profiles, hit goals, armor priorities, pins and class UI")
UnitClass=function() return "드루이드","DRUID" end
GetNumTalents=function() return 1 end
GetTalentInfo=function() return "Nature's Reach","icon",2,4,2,2 end
assert(ns.currentTalentRank(ns.classes[2])==2 and ns.currentTalentRank(ns.classes[1])==nil)
SlashCmdList.BISFITPLAN()
plannerClick("조화");plannerClick("내 특성")
assert(BiSFitCharacter.profiles.balance.target==13)
local boxes={}
for _,node in ipairs(nodes) do if node.kind=="EditBox" then boxes[#boxes+1]=node end end
boxes[1]:SetText("12");plannerClick("조회")
assert(BiSFitCharacter.profiles.balance.target==12)
boxes[1]:SetText("-1");plannerClick("조회")
assert(BiSFitCharacter.profiles.balance.target==12)
plannerClick("주술사");plannerClick("드루이드")
assert(boxes[1].text=="12")
print("OK: detected talent points, manual override, invalid input and saved targets")

assert(SLASH_BISFITPLAN1=="/bis" and SLASH_BISFITPLAN2=="/bisfit" and SLASH_BISFITPLAN3=="/sfit")
local gearButton
for _,node in ipairs(nodes) do
    if rawget(node,"item") and node.item>0 then gearButton=node;break end
end
assert(gearButton);gearButton.hooks.OnClick(gearButton,"LeftButton")
local choice
for _,node in ipairs(nodes) do
    if rawget(node,"id") and node.id~=gearButton.item then choice=node;break end
end
assert(choice);local selected=choice.id
local original=gearButton.item
choice.hooks.OnClick(choice)
assert(BiSFitPlanner.restore:IsShown())
plannerClick("미리보기 · 추천으로 복귀")
assert(gearButton.item==original and not BiSFitPlanner.restore:IsShown())
gearButton.hooks.OnClick(gearButton,"LeftButton");choice.hooks.OnClick(choice)
assert(gearButton.item==selected and not BiSFitCharacter.profiles.balance.pin)
gearButton.hooks.OnClick(gearButton,"RightButton")
assert(BiSFitCharacter.profiles.balance.pin==selected)
gearButton.hooks.OnClick(gearButton,"RightButton")
assert(not BiSFitCharacter.profiles.balance.pin)
local h,m=ns.healingBudget(100,2,50,100,0)
assert(h==200/180 and m==0)
local more,ending=ns.healingBudget(100,2,50,100,5)
assert(more>h and ending>=0 and ending<=100)
for _,role in ipairs({"balance","cat","bear","druidHeal"}) do
    for _,row in ipairs(ns.planRows(role)) do
        local b=assert(row.bench)
        if role=="bear" then assert(b.tmi>0 and b.dtps>0)
        elseif role=="druidHeal" then assert(b.mana>0 and b.heal>0)
        else assert(b.dps>0 and b.se>=0) end
    end
end
local _,tank=ns.plan(ns.classes[2],"bear",{})
for _,row in ipairs(ns.planRows("bear")) do assert(tank.score<=row.bench.tmi) end
for _,role in ipairs({"restoration","druidHeal"}) do
    local class=role=="restoration" and ns.classes[1] or ns.classes[2]
    local _,r=ns.plan(class,role,{})
    assert(r.healing and r.score==r.healing.hps and r.healing.ending>=0)
end
print("OK: measured druid DPS, tank survival ordering and mana-limited healing")

for _,strict in ipairs({false,true}) do
    local caps=ns.maxGearHit("elemental",{target=12},strict)
    local left,right=ns.plan(ns.classes[1],"elemental",{target=100})
    assert(caps==(strict and left or right).hit,"unrestricted maximum-hit witness missing")
end

-- Guard against publishing a shortlist that misses the attainable Elemental raid target.
local elemental=ns.classes[1]
local pure,mixed=ns.plan(elemental,"elemental",{target=12})
assert(pure and mixed and pure.short==0 and mixed.short==0)
assert(mixed.score>=pure.score)
local pinned={target=8,pin=12927,pinSlot=3}
assert(ns.maxGearHit("enhancement",pinned,true)==nil)
local _,leather=ns.plan(elemental,"enhancement",pinned)
assert(leather and leather.hit<=ns.maxGearHit("enhancement",pinned,false))
local baseline=ns.plan(elemental,"enhancement",{target=8})
local step=ns.oneArmorUpgrade(elemental,"enhancement",{target=8},baseline)
if step then assert(step.score>baseline.score) end
assert(type(ns.confirmedDPS)=="table","missing confirmation data")
for _,value in pairs(ns.confirmedDPS) do assert(value[1]>0 and value[2]>0) end
print("OK: feasible hit targets, pinned material limits and independent DPS confirmations")
