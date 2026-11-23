local _, ns = ...
local ui, chooser, info, state, refresh, openChoices
local bg={.045,.055,.075,1}
local gold={1,.78,.39}
local muted={.65,.71,.77}
local teal={.35,.87,.74}
local orange={1,.63,.39}
local gearLeft, gearRight, statRows, tabs = {},{},{},{}
local function fill(frame,r,g,b,a)
    local tx=frame:CreateTexture(nil,"BACKGROUND")
    tx:SetAllPoints();tx:SetColorTexture(r,g,b,a);return tx
end
local function newText(parent,x,y,w,font,align,color)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    t:SetWidth(w);t:SetJustifyH(align or "LEFT");t:SetWordWrap(false)
    if color then t:SetTextColor(unpack(color)) end
    return t
end
local function label(parent,x,y,w,value,font,color)
    local t=newText(parent,x,y,w,font,nil,color);t:SetText(value);return t
end
local function button(parent,x,y,w,h,value,onClick)
    local b=CreateFrame("Button",nil,parent)
    b:SetSize(w,h);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    b.bg=fill(b,.12,.15,.19,1)
    local hl=b:CreateTexture(nil,"HIGHLIGHT");hl:SetAllPoints();hl:SetColorTexture(.6,.8,1,.13)
    b.caption=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");b.caption:SetPoint("CENTER");b.caption:SetText(value)
    b:SetScript("OnClick",onClick);return b
end
local function active(b,on)
    b.bg:SetColorTexture(on and .14 or .10,on and .29 or .13,on and .29 or .17,1)
    b.caption:SetTextColor(unpack(on and teal or muted))
end
local function tooltip(self,id)
    if not id or id==0 then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:"..id)
    GameTooltip:AddLine(ns.data.items[id][2],.95,.75,.45,true)
    GameTooltip:Show()
end
local function hideTip() GameTooltip:Hide() end
local function closeChoices() if chooser then chooser:Hide() end end
local function panel(id,w,h)
    local p=CreateFrame("Frame",id,UIParent)
    p:SetSize(w,h);p:SetPoint("CENTER");p:SetFrameStrata("DIALOG")
    p:EnableMouse(true);p:SetClampedToScreen(true);fill(p,unpack(bg))
    p:Hide();table.insert(UISpecialFrames,id);return p
end
local function itemRow(x,y,slot,mail)
    local f=CreateFrame("Button",nil,ui);f:SetSize(241,29);f:SetPoint("TOPLEFT",ui,"TOPLEFT",x,-y)
    fill(f,slot%2==0 and .085 or .067,.093,.123,1)
    local hi=f:CreateTexture(nil,"HIGHLIGHT");hi:SetAllPoints();hi:SetColorTexture(.4,.7,.8,.16)
    f.tex=f:CreateTexture(nil,"ARTWORK");f.tex:SetPoint("LEFT",3,0);f.tex:SetSize(24,24);f.tex:SetTexCoord(.07,.93,.07,.93)
    f.name=newText(f,32,2,206);f.source=newText(f,32,15,206,"GameFontDisableSmall",nil,muted)
    f:SetScript("OnEnter",function(self) tooltip(self,self.item) end);f:SetScript("OnLeave",hideTip)
    f:RegisterForClicks("LeftButtonUp","RightButtonUp")
    f:SetScript("OnClick",function(_,key)
        if key=="RightButton" then state.pin=nil;closeChoices();refresh() else openChoices(slot,mail) end
    end)
    return f
end
local function paint(f,slot,id)
    f.item=id
    local item=id and ns.data.items[id]
    if not item then f.tex:Hide();f.name:SetText("—");f.source:SetText("");return end
    local file=C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
    f.tex:SetTexture(file or (item[5]~="" and ("Interface\\Icons\\"..item[5])) or 134400);f.tex:Show()
    local prefix=state.pin==id and "|cff6de5bf◆|r " or ""
    f.name:SetText(prefix..ns.itemName(id));f.name:SetTextColor(unpack(item[4]==4 and {.79,.54,1} or {.45,.75,1}))
    f.source:SetText(item[2])
end
local options,page,choiceSlot={},1,0
local function showPage()
    local pages=math.max(1,math.ceil(#options/11));page=math.max(1,math.min(page,pages))
    chooser.page:SetText(page.." / "..pages)
    for i,b in ipairs(chooser.rows) do
        local id=options[(page-1)*11+i];b.id=id
        if id then
            b.caption:SetText(ns.itemName(id));b.desc:SetText(ns.material(choiceSlot,id).."  "..ns.data.items[id][2]);b:Show()
        else b:Hide() end
    end
end
openChoices=function(slot,mail)
    if not chooser then
        chooser=panel("ShamanFitPicker",420,478);chooser:SetParent(ui);chooser:ClearAllPoints();chooser:SetPoint("CENTER",ui);chooser:SetFrameLevel(ui:GetFrameLevel()+12)
        chooser.title=label(chooser,16,15,342,"","GameFontNormalLarge",gold)
        button(chooser,375,9,32,24,"×",closeChoices)
        label(chooser,16,46,395,"아이템을 선택하면 그 아이템을 포함한 조합끼리 비교합니다.",nil,muted)
        chooser.rows={}
        for i=1,11 do
            local b=button(chooser,14,70+(i-1)*31,392,30,"",function(self)
                state.pin=self.id;closeChoices();refresh()
            end)
            b.caption:ClearAllPoints();b.caption:SetPoint("TOPLEFT",b,"TOPLEFT",7,-2);b.caption:SetWidth(375);b.caption:SetJustifyH("LEFT")
            b.desc=newText(b,7,16,376,"GameFontDisableSmall",nil,muted)
            b:SetScript("OnEnter",function(self) tooltip(self,self.id) end);b:SetScript("OnLeave",hideTip)
            chooser.rows[i]=b
        end
        button(chooser,14,427,61,28,"이전",function() page=page-1;showPage() end)
        chooser.page=label(chooser,88,434,66,"")
        button(chooser,153,427,61,28,"다음",function() page=page+1;showPage() end)
        button(chooser,272,427,134,28,"고정 해제",function() state.pin=nil;closeChoices();refresh() end)
    end
    choiceSlot=slot;options=ns.options(state,slot,mail);page=1
    chooser.title:SetText(ns.slotNames[slot].." 고정  ·  "..(mail and "사슬 세팅" or "혼합 세팅"))
    showPage();chooser:Show();hideTip()
end
local function performance(row,spec)
    if not row then return "조건에 맞는 조합 없음" end
    return string.format("%.1f %s",row.perf,spec=="restoration" and "시전 HPS" or "DPS")
end
local function value(v,index)
    if not v then return "—" end
    return ns.isPercent(index) and string.format("%.2f%%",v) or string.format("%.0f",v)
end
refresh=function()
    if not ui or not state then return end
    local spec=state.spec;local mail,mixed=ns.compare(state)
    for k,b in pairs(tabs) do active(b,k==spec) end
    active(ui.rep,state.noRep);ui.rep.caption:SetText(state.noRep and "평판 제외 ✓" or "평판 포함")
    active(ui.tier,state.noTier);ui.tier.caption:SetText(state.noTier and "T0.5 제외 ✓" or "T0.5 포함")
    ui.mailScore:SetText(performance(mail,spec));ui.mixScore:SetText(performance(mixed,spec))
    local diff,percent=ns.difference(mail,mixed)
    ui.delta:SetText(diff and string.format("사슬 − 혼합   %+.1f  (%+.2f%%)",diff,percent) or "사슬 − 혼합   —")
    for i=1,17 do paint(gearLeft[i],i,mail and mail.gear[i]);paint(gearRight[i],i,mixed and mixed.gear[i]) end
    for j,row in ipairs(statRows) do
        local index=ns.statOrders[spec][j]
        if index then
            local a=mail and mail.stats[index];local b=mixed and mixed.stats[index]
            row[1]:SetText(ns.statNames[index]);row[2]:SetText(value(a,index));row[3]:SetText(value(b,index))
            row[4]:SetText((a and b) and string.format(ns.isPercent(index) and "%+.2f" or "%+.0f",a-b) or "—")
        else for _,t in ipairs(row) do t:SetText("") end end
    end
    local details
    if spec=="restoration" then
        details=string.format("하급 치유의 물결 6단계\n1회 평균  %s / %s\n1회 마나  361 / 361\n치유/마나  %s / %s\n유효힐·물의 보호막 발동 제외",
            mail and string.format("%.0f",mail.heal) or "—",mixed and string.format("%.0f",mixed.heal) or "—",
            mail and string.format("%.2f",mail.heal/361) or "—",mixed and string.format("%.2f",mixed.heal/361) or "—")
    else
        details=string.format("타우렌 60 · 우두머리 63 · 180초\n조합당 %d회 · 동일 특성·버프\n평균의 표준오차  %s / %s DPS",
            ns.data.iterations,mail and string.format("%.1f",mail.se) or "—",mixed and string.format("%.1f",mixed.se) or "—")
    end
    ui.details:SetText(details)
    ui.lock:SetText(state.pin and ("고정  ·  "..ns.itemName(state.pin)) or "고정한 장비 없음")
    ui.meta:SetText(string.format("%s  ·  아이템 후보 %d개  ·  %s %d조합  ·  WoWSims %s",ns.data.date,ns.data.catalogSize,ns.specNames[spec],#ns.data.sets[spec],ns.data.revision:sub(1,7)))
    local function sets(r) return r and #r.bonuses>0 and table.concat(r.bonuses,", ") or "—" end
    ui.bonuses:SetText("사슬  "..sets(mail).."\n혼합  "..sets(mixed))
end
local function scale()
    if ui then ui:SetScale(math.min(1,UIParent:GetWidth()*.98/940,UIParent:GetHeight()*.96/680)) end
end
local function initialize()
    ui=panel("ShamanFitWindow",940,680);ui:SetMovable(true);ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart",ui.StartMoving);ui:SetScript("OnDragStop",ui.StopMovingOrSizing)
    ui:SetScript("OnHide",function() closeChoices();if info then info:Hide() end end)
    label(ui,16,14,320,"ShamanFit  |  주술사 프리레이드","GameFontNormalLarge",gold)
    button(ui,892,9,34,27,"×",function() ui:Hide() end)
    for i,spec in ipairs({"enhancement","elemental","restoration"}) do
        tabs[spec]=button(ui,16+(i-1)*62,46,58,26,ns.specNames[spec],function()
            state.spec=spec;state.pin=nil;closeChoices();refresh()
        end)
    end
    ui.rep=button(ui,216,46,93,26,"평판 포함",function()
        state.noRep=not state.noRep;closeChoices()
        local _,mixed=ns.compare(state);if not mixed then state.pin=nil end
        refresh()
    end)
    ui.tier=button(ui,317,46,95,26,"T0.5 포함",function()
        state.noTier=not state.noTier;closeChoices()
        local _,mixed=ns.compare(state);if not mixed then state.pin=nil end
        refresh()
    end)
    ui.lock=label(ui,425,54,258,"",nil,teal)
    button(ui,697,46,92,26,"계산 기준",function()
        closeChoices()
        if not info then
            info=panel("ShamanFitProfile",530,280);info:SetParent(ui);info:ClearAllPoints();info:SetPoint("CENTER",ui);info:SetFrameLevel(ui:GetFrameLevel()+14)
            label(info,18,16,460,"추천과 계산 기준","GameFontNormalLarge",gold)
            button(info,483,10,32,24,"×",function() info:Hide() end)
            info.body=newText(info,18,55,492,"GameFontHighlight");info.body:SetWordWrap(true);info.body:SetSpacing(4)
        end
        local spec=state.spec
        local detail=spec=="restoration" and "타우렌 · 하급 치유의 물결 6단계. 정화와 해일의 집중 각각 5점. 주문 극대화와 가속을 반영한 시전 중 평균입니다. 초과 치유, 다중 대상, 마나 고갈과 일시 발동은 제외합니다." or "타우렌 · 63레벨 단일 우두머리 · 180초. WoWSims의 해당 특성 기본 버프·소모품·딜 사이클에서 장비를 교체했습니다. 모든 세트는 마법부여 없이 비교합니다."
        local gameVersion,gameBuild=GetBuildInfo()
        info.body:SetText(detail.."\n\n특성  "..ns.data.builds[spec].."\n\n현재 클라이언트  "..gameVersion.." ("..gameBuild..")\n아이템·시뮬 데이터  "..ns.data.date.." · "..ns.data.revision:sub(1,12).."\n\n표의 1순위는 이 버전에 수록된 후보 조합 안에서 계산했습니다.")
        info:Show()
    end)
    button(ui,798,46,128,26,"고정 해제",function() state.pin=nil;closeChoices();refresh() end)
    label(ui,70,91,125,"사슬 전용","GameFontNormal",teal);label(ui,321,91,135,"혼합 허용","GameFontNormal",orange)
    ui.mailScore=newText(ui,70,111,230,"GameFontNormalLarge",nil,teal)
    ui.mixScore=newText(ui,321,111,230,"GameFontNormalLarge",nil,orange)
    ui.delta=newText(ui,578,91,346,"GameFontNormalLarge",nil,gold)
    for i=1,17 do
        local y=145+(i-1)*29
        label(ui,13,y+8,54,ns.slotNames[i],nil,muted)
        gearLeft[i]=itemRow(68,y,i,true);gearRight[i]=itemRow(317,y,i,false)
    end
    local xs={578,683,766,847};local widths={104,76,76,76}
    for k,v in ipairs({"참조 캐릭터","사슬","혼합","차이"}) do
        local t=newText(ui,xs[k],145,widths[k],"GameFontNormalSmall",k==1 and "LEFT" or "RIGHT",gold);t:SetText(v)
    end
    for j=1,12 do local row={}
        for k=1,4 do row[k]=newText(ui,xs[k],172+(j-1)*21,widths[k],"GameFontHighlightSmall",k==1 and "LEFT" or "RIGHT",k==4 and teal or nil) end
        statRows[j]=row
    end
    label(ui,578,436,335,"계산 조건  ·  사슬 / 혼합","GameFontNormal",gold)
    ui.details=newText(ui,578,462,346);ui.details:SetWordWrap(true);ui.details:SetSpacing(3)
    label(ui,578,559,342,"활성 세트 효과","GameFontNormal",gold)
    ui.bonuses=newText(ui,578,582,345,"GameFontDisableSmall",nil,muted);ui.bonuses:SetWordWrap(true);ui.bonuses:SetHeight(60);ui.bonuses:SetJustifyV("TOP")
    ui.meta=newText(ui,15,651,570,"GameFontDisableSmall",nil,muted)
    label(ui,578,651,346,"장비 클릭으로 고정 · 우클릭으로 해제",nil,muted)
    scale()
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN");events:RegisterEvent("DISPLAY_SIZE_CHANGED");events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then
        state=ns.newState(ShamanFitCharacter);ShamanFitCharacter=state
    elseif event=="DISPLAY_SIZE_CHANGED" then scale()
    elseif ui and ui:IsShown() and not ui.pending then
        ui.pending=true;C_Timer.After(.15,function() ui.pending=nil;if ui:IsShown() then refresh() end end)
    end
end)
SLASH_SHAMANFIT1="/shamanfit"
SLASH_SHAMANFIT2="/sfit"
SlashCmdList.SHAMANFIT=function()
    if not state then state=ns.newState(ShamanFitCharacter);ShamanFitCharacter=state end
    if not ui then initialize() end
    if ui:IsShown() then ui:Hide() else ui:Show();refresh() end
end
