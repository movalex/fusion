fl = comp.CurrentFrame.FlowView

function _round(num, n) 
    local mult = 10^(n or 0)
    return math.floor(num*mult+0.5)/mult
end

comp:StartUndo("Stack Tools Vertically")
comp:Lock()
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool
if active_tool == nil then
    active_tool = selected_tools[1]
    print('active tool'.. active_tool.Name)
end
active_X, active_Y = fl:GetPos(active_tool)
print(active_X..':'..active_Y)
for k,v in pairs(selected_tools) do
    if (v ~= active_tool) then
        _TEMP_X, _TEMP_Y = fl:GetPos(v)
        print(_round(_TEMP_Y,2)..' '.._round(active_Y,2))
        -- check if nodes have the same Y value
        if _round(_TEMP_Y, 2) == _round(active_Y,2) then 
            newpos = _TEMP_Y + (k-1)
        else
            newpos = _TEMP_Y
        end
        fl:SetPos(v, active_X, newpos)
    end
end
comp:Unlock()
comp:EndUndo()
