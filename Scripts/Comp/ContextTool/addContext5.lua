local ContextNo = 5
if not tool then
    tool = comp.ActiveTool
end
local getToolName = comp:GetData("ContextTool."..ContextNo)
local prevTool = comp:FindTool(getToolName)
if prevTool and prevTool ~= tool then
    prevTool.Comments[fu.TIME_UNDEFINED] = ""
end
comp:SetData("ContextTool."..ContextNo, tool.Name)
print(tool.Name ..' is set as context view #'..ContextNo)
tool.Comments = 'Context ' .. ContextNo
