-- local CONTEXT = 1
if not tool then
    tool = comp.ActiveTool
end
local getToolName = comp:GetData("ContextTool."..CONTEXT)
local prevTool = comp:FindTool(getToolName)
if prevTool and prevTool ~= tool then
    prevTool.Comments[fu.TIME_UNDEFINED] = ""
end
comp:SetData("ContextTool."..CONTEXT, tool.Name)
print(tool.Name ..' is set as context view #'..CONTEXT)
tool.Comments = 'Context ' .. CONTEXT
