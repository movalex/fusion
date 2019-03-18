fl = comp.CurrentFrame.FlowView

comp:StartUndo("Allign Tools Vertically")
-- comp:Lock()
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if active_tool == nil then
    active_tool = selected_tools[1]
end

active_X, active_Y = fl:GetPos(active_tool)

for num, tool in pairs(selected_tools) do
    _TEMP_X, TEMP_Y = fl:GetPos(tool)
    if tool ~= active_tool then
        -- check if nodes have the same Y value
		-- floor the values for switching between horiz and vertical allignment
        if math.floor(TEMP_Y) == math.floor(active_Y) then 
            newpos = TEMP_Y + (num-1)
        else
            newpos = TEMP_Y
        end
        fl:SetPos(tool, active_X, newpos)
    end
end
-- comp:Unlock()
comp:EndUndo()