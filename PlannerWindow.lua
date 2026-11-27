local _,ns=...
local frame,role,classIndex,settings,redraw
local selectors,rows={},{}
local db,defaultTarget,rankSource
local width,height=1110,810
local statFields={{0,"힘"},{1,"민첩"},{2,"체력"},{3,"지능"},{4,"치유력"},{5,"주문 피해"},{17,"적중 평점"}}
local function text(parent,x,y,s)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y);f:SetText(s or "")
    return f
end
local function button(parent,x,y,w,s,click)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,24);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
    b:SetText(s);b:SetScript("OnClick",click);return b
end
local function tip(b,message)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(message(),1,1,1,1,true);GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
local preview,picker
local function openPicker(slot,side)
    local options={slot=slot,side=side,ids={}}
    ns.plan(ns.classes[classIndex],role,settings,options)
    local ids={}
    for id in pairs(options.ids) do ids[#ids+1]=id end
    table.sort(ids,function(a,b)
        local x,y=ns.itemEP[role][a],ns.itemEP[role][b]
        if x==y then return a<b end
        return x>y
    end)
    local ranks={}
    local previousEP,rank
    for index,id in ipairs(ids) do
        local ep=ns.itemEP[role][id]
        if ep~=previousEP then rank=index end
        ranks[id]=rank
        previousEP=ep
    end
    if not picker then
        picker=CreateFrame("Frame",nil,frame)
        picker:SetSize(410,342);picker:SetPoint("CENTER");picker:EnableMouse(true)
        picker:SetFrameLevel(frame:GetFrameLevel()+10)
        local bg=picker:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.05,.06,.08,1)
        picker.title=text(picker,12,10)
        button(picker,354,4,46,"닫기",function() picker:Hide() end)
        picker.entries={}
        for i=1,10 do
            local b=button(picker,12,36+(i-1)*27,386,"",function(self)
                preview={slot=picker.slot,side=picker.side,id=self.id}
                picker:Hide();redraw()
            end)
            b:SetScript("OnEnter",function(self)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:"..self.id)
                GameTooltip:AddLine(ns.data.items[self.id][2],1,.8,.5,true);GameTooltip:Show()
            end)
            b:SetScript("OnLeave",function() GameTooltip:Hide() end)
            picker.entries[i]=b
        end
        function picker:render()
            local pages=math.max(1,math.ceil(#self.ids/10))
            self.page=math.max(1,math.min(self.page,pages))
            self.title:SetText((self.slot==17 and "성물" or ns.slotNames[self.slot]).." · 부위 EP 순위 · "..#self.ids.."개 · "..self.page.."/"..pages)
            for i,b in ipairs(self.entries) do
                b.id=self.ids[(self.page-1)*10+i]
                if b.id then
                    b:SetText(string.format("%d위  |  %.2f EP  |  %s",self.ranks[b.id],ns.itemEP[role][b.id],ns.slotItemName(self.slot,b.id)));b:Show()
                else b:Hide() end
            end
        end
        button(picker,12,310,75,"이전",function() picker.page=picker.page-1;picker:render() end)
        button(picker,323,310,75,"다음",function() picker.page=picker.page+1;picker:render() end)
    end
    picker.ranks=ranks
    picker.slot,picker.side,picker.ids,picker.page=slot,side,ids,1
    picker:render();picker:Show()
end
local function numberBox(x)
    local box=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
    box:SetSize(44,22);box:SetPoint("TOPLEFT",frame,"TOPLEFT",x,-78)
    box:SetAutoFocus(false);box:SetMaxLetters(5);return box
end
local function profile()
    db.profiles[role]=db.profiles[role] or {prefer=true}
    return db.profiles[role]
end
local function selectRole(key)
    preview=nil
    role=key
    db.lastRole[classIndex]=key
    settings=profile()
    if classIndex==1 and settings.noRep==nil then
        settings.noRep=db.noRep==true;settings.noTier=db.noTier==true
    end
    frame.target:SetText(tostring(settings.target or ns.roles[role][2] or 0))
    local class=ns.classes[classIndex]
    local rank=ns.currentTalentRank(class)
    rankSource=rank~=nil and "내 특성" or "미리보기"
    frame.bonus:SetText(tostring(settings.rank or rank or 0))
    defaultTarget=ns.roles[role][2]
    if role=="bear" and settings.target==nil then
        defaultTarget=0;frame.target:SetText("0")
    elseif not settings.target and rank and defaultTarget then
        defaultTarget=defaultTarget-rank*class.talent.step
        frame.target:SetText(tostring(defaultTarget))
    end
    redraw()
end
local function selectClass(index)
    classIndex=index
    local c=ns.classes[index]
    for i,b in ipairs(selectors) do
        local key=c.roles[i]
        if key then b.key=key;b:SetText(ns.roles[key][1]);b:Show() else b:Hide() end
    end
    selectRole(db.lastRole[index] or c.roles[1])
end
local function submit(useBonus)
    local limit=ns.roles[role][2]
    if not limit then return end
    local box=useBonus and frame.bonus or frame.target
    local n=tonumber(box:GetText())
    if not n or n<0 or n>(useBonus and ns.classes[classIndex].talent.max or 100) then
        frame.notice:SetText("입력 범위 0–"..(useBonus and ns.classes[classIndex].talent.max or 100).."%");return
    end
    if useBonus and n~=math.floor(n) then frame.notice:SetText("특성 포인트는 정수로 입력하세요.");return end
    if useBonus then settings.rank=n;rankSource="선택한 특성";n=limit-n*ns.classes[classIndex].talent.step;frame.target:SetText(tostring(n)) end
    preview=nil;settings.target=n;box:ClearFocus();redraw()
end
local function build()
    frame=CreateFrame("Frame","BiSFitPlanner",UIParent)
    frame:SetSize(width,height);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true);frame:SetMovable(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",frame.StartMoving);frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    local bg=frame:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.045,.055,.075,.98)
    table.insert(UISpecialFrames,"BiSFitPlanner")
    text(frame,16,16,"BiSFit")
    for i,c in ipairs(ns.classes) do button(frame,148+(i-1)*104,8,100,c.name,function() selectClass(i) end) end
    local details=button(frame,958,8,94,"계산 기준 ⓘ",function() end)
    tip(details,function() return frame.criteria end)
    button(frame,1060,8,38,"×",function() frame:Hide() end)
    for i=1,4 do selectors[i]=button(frame,16+(i-1)*109,42,105,"",function(self) selectRole(self.key) end) end
    frame.mode=button(frame,475,42,128,"",function() preview=nil;settings.prefer=not settings.prefer;redraw() end)
    tip(frame.mode,function() local c=ns.classes[classIndex]
        local ranking = role=="bear" and "TMI가 낮은 순, 동점이면 받는 DPS가 낮은 순" or
            (role=="restoration" or role=="druidHeal") and "지속 HPS가 높은 순" or "평균 DPS가 높은 순"
        return c.material.." 우선은 적중 부족분이 가장 작은 후보 중 다른 재질이 가장 적은 세트를 고릅니다. 같은 부위 수에서는 "..ranking.."입니다."
    end)
    frame.unpin=button(frame,615,42,80,"고정 해제",function() preview=nil;settings.pin=nil;settings.pinSlot=nil;redraw() end)
    frame.goalLabel=text(frame,16,84)
    frame.target=numberBox(156);frame.apply=button(frame,205,77,62,"조회",function() submit(false) end)
    frame.bonusLabel=text(frame,282,84,"적중 특성 (포인트)")
    frame.bonus=numberBox(408);frame.useBonus=button(frame,458,77,125,"레이드 목표 적용",function() submit(true) end)
    frame.mine=button(frame,593,77,92,"내 특성",function()
        local rank=ns.currentTalentRank(ns.classes[classIndex])
        if rank==nil then frame.notice:SetText("현재 캐릭터 특성 확인 불가 · 포인트를 직접 입력하세요.");return end
        frame.bonus:SetText(tostring(rank));submit(true)
    end)
    frame.rep=button(frame,700,42,90,"",function() preview=nil;settings.noRep=not settings.noRep;redraw() end)
    frame.tier=button(frame,795,42,90,"",function() preview=nil;settings.noTier=not settings.noTier;redraw() end)
    frame.target:SetScript("OnEnterPressed",function() submit(false) end)
    frame.bonus:SetScript("OnEnterPressed",function() submit(true) end)
    frame.notice=text(frame,16,114)
    frame.head={text(frame,86,142),text(frame,382,142)}
    frame.restore=button(frame,0,0,142,"미리보기 · 추천으로 복귀",function()
        preview=nil
        redraw()
    end)
    frame.materialNote=text(frame,86,178)
    frame.status={text(frame,86,160),text(frame,382,160)}
    for slot=1,17 do
        rows[slot]={};local y=202+(slot-1)*34
        text(frame,14,y+9,slot==17 and "성물" or ns.slotNames[slot])
        for side=1,2 do
            local b=CreateFrame("Button",nil,frame)
            b:SetSize(288,33)
            b:SetPoint("TOPLEFT",frame,"TOPLEFT",82+(side-1)*296,-y)
            b:SetScript("OnClick",function(self,key)
                if key~="RightButton" then openPicker(slot,side);return end
                if not self.item or self.item==0 then return end
                preview=nil
                if settings.pin==self.item then
                    settings.pin=nil;settings.pinSlot=nil
                else settings.pin=self.item;settings.pinSlot=slot end
                redraw()
            end)
            b:RegisterForClicks("LeftButtonUp","RightButtonUp")
            local bg=b:CreateTexture(nil,"BACKGROUND")
            bg:SetAllPoints()
            local shade=slot%2==0 and .085 or .065
            bg:SetColorTexture(shade,shade+.012,shade+.025,1)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
            b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(29,29);b.icon:SetPoint("LEFT",3,0)
            b.title=text(b,38,2)
            b.source=text(b,38,17)
            for _,line in ipairs({b.title,b.source}) do
                line:SetWidth(245);line:SetJustifyH("LEFT");line:SetWordWrap(false)
            end
            b.source:SetTextColor(.69,.73,.78)
            b:SetScript("OnEnter",function(self)
                if not self.item or self.item==0 then return end
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:"..self.item)
                GameTooltip:AddLine(ns.data.items[self.item][2],1,.8,.5,true)
                GameTooltip:AddLine(string.format("아이템 기본 EP %.2f",ns.itemEP[role][self.item]),.6,1,.8)
                if self.delta~=nil then
                    GameTooltip:AddLine(string.format("반대 열의 이 부위만 교체  %+.2f %s",self.delta,self.unit),1,.84,.5)
                elseif self.unmeasured then GameTooltip:AddLine("이 단일 교체 조합은 미측정",.8,.8,.8) end
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave",function() GameTooltip:Hide() end)
            rows[slot][side]=b
        end
    end
    frame.footer=text(frame,16,784)
    frame.summary=text(frame,685,142)
    frame.summary:SetWidth(405);frame.summary:SetJustifyH("LEFT")
    text(frame,685,198,"장비 기본 능력치")
    frame.statHeaders={text(frame,836,198),text(frame,929,198,"혼합"),text(frame,1026,198,"차이")}
    frame.statRows={}
    for index,field in ipairs(statFields) do
        local y=224+(index-1)*22
        text(frame,685,y,field[2])
        frame.statRows[index]={text(frame,836,y),text(frame,929,y),text(frame,1026,y)}
    end
    text(frame,685,401,"계산 기준")
    frame.conditions=text(frame,685,425)
    frame.conditions:SetWidth(402);frame.conditions:SetJustifyH("LEFT")
    frame.conditions:SetSpacing(2)
end
redraw=function()
    local c=ns.classes[classIndex]
    local limit=ns.roles[role][2]
    for _,widget in ipairs({frame.target,frame.apply,frame.goalLabel,frame.bonusLabel,frame.bonus,frame.useBonus,frame.mine}) do
        if limit then widget:Show() else widget:Hide() end
    end
    frame.goalLabel:SetText("장비 "..(ns.roles[role][3] or "").." 적중 (%)")
    local mode=c.material..(settings.prefer and " 우선" or "만")
    frame.mode:SetText(mode)
    if classIndex==1 then
        frame.rep:SetText(settings.noRep and "평판 제외" or "평판 포함")
        frame.tier:SetText(settings.noTier and "T0.5 제외" or "T0.5 포함")
        frame.rep:Show();frame.tier:Show()
    else frame.rep:Hide();frame.tier:Hide() end
    frame.bonusLabel:SetText("적중 특성 ("..c.talent.max.."점 만점)")
    for _,b in ipairs(selectors) do if b.key==role then b:Disable() else b:Enable() end end
    local query=settings
    if limit and settings.target==nil then
        query=setmetatable({target=defaultTarget or limit},{__index=settings})
    end
    if picker then picker:Hide() end
    if preview then
        frame.restore:ClearAllPoints()
        frame.restore:SetPoint("TOPRIGHT",frame,"TOPLEFT",945,-8)
        frame.restore:Show()
    else
        frame.restore:Hide()
    end
    local left,right=ns.plan(c,role,query,nil,preview)
    local pureMax=limit and ns.maxGearHit(role,query,true)
    local shortage=pureMax and (query.target or 0)-pureMax
    frame.materialNote:SetText(left and shortage and shortage>0 and
        string.format("%s만으론 %.1f%%p 부족 · 안돼 돌아가~",c.material,shortage) or "")
    local changed = {}
    local unit=role=="bear" and "TMI ↓" or (role=="restoration" or role=="druidHeal") and "지속 HPS" or "DPS"
    frame.notice:SetText(c.name.." · "..ns.roles[role][1]..(limit and (" · "..(settings.target and "저장한 장비 목표" or rankSource).." "..(settings.target or defaultTarget).."%") or "").."   "..(settings.pin and "양쪽 고정 · "..(settings.pinSlot and ((settings.pinSlot==17 and "성물" or ns.slotNames[settings.pinSlot]).." — ") or "")..ns.itemName(settings.pin) or "좌클릭 교체 · 우클릭 고정/해제"))
    for side=1,2 do
        local r=left
        if side==2 then r=right end
        local rankLabel=preview and preview.side==side and "미리보기" or "측정 세트 1위"
        frame.head[side]:SetText((side==1 and mode or "혼합 허용")..(r and string.format(" · %s · %.1f %s",rankLabel,r.score,unit) or ""))
        frame.status[side]:SetText(limit and (ns.planStatus(r,side==1 and c or nil)..(r and string.format(" · 장비 %.1f%%",r.hit) or "")) or (r and "치유 기준" or "조건에 맞는 후보 없음"))
        if r and r.healing then
            frame.status[side]:SetText(string.format("5초당 마나 회복 %.1f · 종료 마나 %.0f",r.healing.mp5,r.healing.ending))
        elseif r and r.dtps then
            frame.status[side]:SetText(string.format("%s · 받는 DPS %.1f",ns.planStatus(r,side==1 and c or nil),r.dtps))
        end
        for slot,line in ipairs(rows) do
            local b=line[side];local id=r and r.row.gear[slot];b.item=id
            local opposite=left
            if side==1 then opposite=right end
            local differs = r and opposite and id ~= opposite.row.gear[slot]
            if side==1 and differs then changed[#changed+1]=slot==17 and "성물" or ns.slotNames[slot] end
            b.delta=ns.swapDelta(role,opposite and opposite.row,slot,id)
            b.unmeasured=opposite and id and b.delta==nil
            b.unit=unit
            if id and id>0 then
                b.title:SetText((differs and "↔ " or "")..(id==settings.pin and "◆ " or "")..ns.slotItemName(slot,id))
                local info=ns.data.items[id]
                local color=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[info[4]]
                b.title:SetTextColor(color and color.r or 1,color and color.g or 1,color and color.b or 1)
                b.source:SetText(info[2] or "")
                local icon=C_Item.GetItemIconByID(id)
                if not icon and info[5] and info[5]~="" then icon="Interface\\Icons\\"..info[5] end
                b.icon:SetTexture(icon or 134400);b.icon:Show()
            else b.title:SetText("—");b.source:SetText("");b.icon:Hide() end
        end
    end
    local delta=""
    local confirmation=""
    if left and right then
        if left.short>0 or right.short>0 then
            delta=" · 적중 목표 미달 · 동조건 성능 비교 보류"
        elseif #changed==0 then
            delta=" · 양쪽 장비 동일"
        else
            local diff=left.score-right.score
            delta=string.format(" · 혼합 대비 %+.2f %s (%+.2f%%) · 교체 %d부위",diff,unit,100*diff/right.score,#changed)
            if unit=="DPS" then
                local lm,rm=left.row.bench or left.row,right.row.bench or right.row
                local confirmed=ns.confirmedDPS or {}
                local l=confirmed[role.."/"..table.concat(left.row.gear,",")]
                local r=confirmed[role.."/"..table.concat(right.row.gear,",")]
                if l and r then
                    local difference=l[1]-r[1]
                    local margin=1.96*math.sqrt(l[2]^2+r[2]^2)
                    confirmation=string.format("\n독립 재측정 각 6,400회 · 차이 %+.2f ± %.2f DPS (약 95%%)",difference,margin)
                    if math.abs(difference)<=margin then delta=delta.." · 우열 불분명" end
                elseif math.abs(diff)<=2*((lm.se or 0)+(rm.se or 0)) then
                    delta=delta.." · 근소한 차이"
                end
            end
        end
    end
    frame.statHeaders[1]:SetText(mode)
    for index,field in ipairs(statFields) do
        local totals={}
        for side,result in ipairs({left or false,right or false}) do
            if result then
                local sum=0
                for _,id in ipairs(result.row.gear) do
                    sum=sum+((ns.gearStats[id] or {})[field[1]] or 0)
                end
                totals[side]=sum
            end
            frame.statRows[index][side]:SetText(result and string.format("%.0f",totals[side]) or "—")
        end
        frame.statRows[index][3]:SetText(left and right and string.format("%+.0f",totals[1]-totals[2]) or "—")
    end
    local criteria
    if classIndex==1 then
        criteria=role=="restoration" and "하급 치유의 물결 6단계 · 180초 고정 MP5 모델" or
            ("63레벨 우두머리 · 평균 5분(4~6분) · 조합당 "..ns.data.iterations.."회")
        criteria=criteria.."\n참조 특성  "..ns.data.builds[role]
        for i,r in ipairs({left or false,right or false}) do
            if r then criteria=criteria.."\n"..(i==1 and mode or "혼합").." 세트 효과  "..table.concat(r.row.bonuses or {},", ") end
        end
    else
        criteria=role=="druidHeal" and "치유의 손길 10단계 · 180초 고정 MP5 모델 · 초과치유 제외" or
            role=="bear" and "63레벨 우두머리 · 180초 × "..ns.druidIterations.bear.."회 · 6초 TMI 낮은 순, 동점이면 받는 DPS" or
            "WoWSims · 63레벨 단일 우두머리 · 평균 5분(4~6분) × "..ns.druidIterations.dps.."회 평균 DPS"
    end
    if unit=="DPS" then
        for side=1,2 do
            local strict=side==1 and not settings.prefer
            local maxHit=ns.maxGearHit(role,query,strict)
            if maxHit then
                local label=side==1 and mode or "혼합"
                criteria=criteria..string.format("\n%s 등록 장비 최대 적중 %.1f%%",label,maxHit)
                local result=right
                if side==1 then result=left end
                if not preview and maxHit>=(query.target or 0) and (not result or result.short>0) then
                    frame.status[side]:SetText("목표 달성 가능 · 충족한 측정 후보 없음")
                end
            end
        end
    end
    for side,r in ipairs({left or false,right or false}) do
        if r then
            local se=r.row.bench and r.row.bench.se or r.row.se
            if se and se>0 then
                criteria=criteria..string.format("\n%s DPS 표준오차 %.2f",side==1 and mode or "혼합",se)
            end
        end
    end
    if unit=="DPS" and not preview and left and left.other==0 and left.short==0 then
        local step,slot=ns.oneArmorUpgrade(c,role,query,left)
        if step then
            criteria=criteria..string.format("\n한 부위만 교체 · %s · %s · %+.2f DPS",
                ns.slotNames[slot],ns.itemName(step.item),step.score-left.score)
        else
            criteria=criteria.."\n한 부위만 교체 · 적중을 유지하며 DPS가 오르는 측정 후보 없음"
        end
    end
    if #changed>0 then criteria=criteria.."\n교체 부위 · "..table.concat(changed,", ") end
    frame.criteria=criteria..confirmation.."\n등록 후보 내 비교 · 데이터 "..ns.data.date
    frame.conditions:SetText(frame.criteria)
    frame.summary:SetText((delta:gsub("^ · ","")))
    frame.footer:SetText("등록 후보 "..#ns.planRows(role).."조합 · 좌클릭 교체 · 우클릭 고정/해제")
end
SLASH_BISFITPLAN1="/bis"
SLASH_BISFITPLAN2="/bisfit"
SLASH_BISFITPLAN3="/sfit"
SlashCmdList.BISFITPLAN=function()
    if frame and frame:IsShown() then frame:Hide();return end
    BiSFitCharacter=BiSFitCharacter or {}
    db=BiSFitCharacter
    if not db.profiles then
        db.profiles={}
        if db.spec and db.pin then db.profiles[db.spec]={pin=db.pin} end
    end
    db.lastRole=db.lastRole or {}
    if not frame then build() end
    frame:SetScale(math.min(1,UIParent:GetWidth()*.98/width,UIParent:GetHeight()*.96/height))
    frame:Show()
    selectClass(classIndex or (UnitClass and select(2,UnitClass("player"))=="DRUID" and 2 or 1))
end
