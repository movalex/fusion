fl = comp.CurrentFrame.FlowView

comp:StartUndo("Align Tools Horizontally")
-- comp:Lock()
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if not active_tool then
	active_tool = selected_tools[1]
end
	 
active_X, active_Y = fl:GetPos(active_tool)

for num, tool in pairs(selected_tools) do
	TEMP_X, _TEMP_Y = fl:GetPos(tool)
	if tool ~= active_tool then
		-- check if nodes have the same X value
		-- floor the values for switching between horiz and vertical allignment
		if math.floor(TEMP_X) == math.floor(active_X) then
			newpos = TEMP_X + (num - 1)
		else
			newpos = TEMP_X
		end
		fl:SetPos(tool, newpos, active_Y)
	end
end

-- comp:Unlock()
comp:EndUndo()