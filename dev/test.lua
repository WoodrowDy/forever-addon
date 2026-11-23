-- Run at the addon repository root: lua5.1 dev/test.lua
local ns={}
local function loadAddon(name) assert(loadfile(name..".lua"))("ShamanFit",ns) end
loadAddon("Data");loadAddon("Compare")
local d=ns.data
assert(d.items[277117][2]:find("그리즐"));assert(d.items[11726][2]:find("고로쉬"))
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
loadAddon("Druid")
C_Item={GetItemIconByID=function(id) return id end}
loadAddon("Window")
events.PLAYER_LOGIN.hooks.OnEvent(nil,"PLAYER_LOGIN")
SlashCmdList.SHAMANFIT();assert(ShamanFitWindow:IsShown())
for _,wanted in ipairs({"정기","복원","고양"}) do
    for _,b in ipairs(nodes) do if b.kind=="Button" and type(rawget(b,"caption"))=="table" and b.caption.text==wanted then b.hooks.OnClick(b);break end end
end
assert(ShamanFitCharacter.spec=="enhancement")
local function clickButton(text)
    for _,b in ipairs(nodes) do
        if b.kind=="Button" and rawget(b,"caption") and b.caption.text==text then b.hooks.OnClick(b);return end
    end
    error("missing button "..text)
end
clickButton("평판 포함");assert(ShamanFitCharacter.noRep)
clickButton("T0.5 포함");assert(ShamanFitCharacter.noTier)
clickButton("계산 기준");assert(ShamanFitProfile:IsShown());ShamanFitProfile:Hide()
local hit
for _,b in ipairs(nodes) do if b.kind=="Button" and type(rawget(b,"item"))=="number" and b.item>0 then hit=b;break end end
assert(hit);hit.hooks.OnClick(hit,"LeftButton");assert(ShamanFitPicker:IsShown())
local row
for _,b in ipairs(nodes) do if rawget(b,"id") and b.id>0 then row=b;break end end
assert(row);row.hooks.OnClick(row);assert(ShamanFitCharacter.pin==row.id)
hit.hooks.OnClick(hit,"RightButton");assert(not ShamanFitCharacter.pin)
SlashCmdList.SHAMANFIT();assert(not ShamanFitWindow:IsShown())
SlashCmdList.SHAMANFIT()
clickButton("드루이드")
local druidRow
for _,node in ipairs(nodes) do if node.item==226773 then druidRow=node;break end end
assert(druidRow and druidRow.hooks.OnEnter)
function GameTooltip:SetHyperlink(link) self.link=link end
druidRow.hooks.OnEnter(druidRow);assert(GameTooltip.link=="item:226773")
clickButton("야성 · 곰");assert(druidRow.item==270117)
clickButton("주술사");clickButton("드루이드");assert(druidRow.item==270117)
SlashCmdList.SHAMANFIT();assert(not ShamanFitWindow:IsShown())
print("OK: three specs, "..totals.." complete sets, armor, reputation, pins, deltas, window and controls")
