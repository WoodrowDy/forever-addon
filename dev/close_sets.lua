-- Export distinct near-tied finalists for confirmation on independent random seeds.
local ns={}
for _,file in ipairs({"Data","Compare","Classes/Shaman","Classes/Druid","PlannerData","Planner"}) do
    assert(loadfile(file..".lua"))("BiSFit",ns)
end
for _,profile in ipairs({{"enhancement",1,8},{"elemental",1,17},{"cat",2,8},{"balance",2,17}}) do
    local role,class,cap=unpack(profile)
    local emitted={}
    for target=0,cap do
        for _,prefer in ipairs({false,true}) do
            local a,b=ns.plan(ns.classes[class],role,{target=target,prefer=prefer})
            if a and b and a.short==0 and b.short==0 and a.row~=b.row then
                local m,n=a.row.bench or a.row,b.row.bench or b.row
                if math.abs(a.score-b.score)<=2*(m.se+n.se) then
                    for _,candidate in ipairs({a,b}) do
                        local key=table.concat(candidate.row.gear,",")
                        if not emitted[key] then print(role,key);emitted[key]=true end
                    end
                end
            end
        end
    end
end
