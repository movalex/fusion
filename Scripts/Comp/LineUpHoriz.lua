fl = comp.CurrentFrame.FlowView

comp:StartUndo("Align Tools Horizontally")
comp:Lock()
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if active_tool == nil then
	active_tool = selected_tools[1]
end

active_X, active_Y = fl:GetPos(active_tool)

for pos, tool in pairs(selected_tools) do
	if tool ~= active_tool then
		_TEMP_X, _TEMP_Y = fl:GetPos(tool)
		-- check if nodes have the same X value
		if _TEMP_X == active_X then
			newpos = _TEMP_X + (pos - 1)
		else
			newpos = _TEMP_X
		end
		fl:SetPos(tool, newpos, active_Y)
	end
end

comp:Unlock()
comp:EndUndo()
