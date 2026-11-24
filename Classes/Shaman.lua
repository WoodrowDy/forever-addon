local _, ns = ...
ns.classes = {{
    name="주술사", token="SHAMAN", armor=3, material="사슬",
    roles={"enhancement","elemental","restoration"},
    talent={tree=3,tier=1,column=3,spell=16179,name="Tidal Focus",max=5,step=1},
}}
ns.roles = {
    enhancement={"고양",8,"근접"}, elemental={"정기",17,"주문"}, restoration={"복원"},
}
