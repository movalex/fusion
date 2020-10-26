-- local CONTEXT = 1
tool = comp.ActiveTool or comp:GetToolList(true)[1] 
if not tool then
    print ('no tool selected')
else
    local getPreviousToolName = comp:GetData("ContextTool."..CONTEXT)
    local previousTool = comp:FindTool(getPreviousToolName)
    if previousTool and previousTool ~= tool then
        previousTool.Comments[fu.TIME_UNDEFINED] = ""
    end
    comp:SetData("ContextTool."..CONTEXT, tool.Name)
    print(tool.Name ..' is set as context view #'..CONTEXT)
    tool.Comments = 'Context ' .. CONTEXT
end
