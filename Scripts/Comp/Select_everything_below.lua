local selected_tools = comp:GetToolList(true)

if (#selected_tools) == 0 then

    print('Select a node as origin')

else

	local allTools = comp:GetToolList(false)
	local active_tool = comp.ActiveTool

	if not active_tool then
	    active_tool = selected_tools[1]
	end

	local flow = comp.CurrentFrame.FlowView
	local active_X, active_Y = flow:GetPos(active_tool)

	-- De-select org tool
	flow:Select()

	print("Start!")

	comp:Lock()
	for num, tool in ipairs(allTools) do
		if tool:GetAttrs().TOOLB_Visible == true then
			--print(tool.Name)
	   		local X, Y = flow:GetPos(tool)
	   		if Y > active_Y then
	   		    -- Select new tool
	   			flow:Select(tool)
	   		end
		end
	end
	comp:Unlock()

	print("Done!")

end