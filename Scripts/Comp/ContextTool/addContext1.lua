if not tool then
    tool = comp.ActiveTool
end
local contextNo = 1
local prevTool = comp:FindTool(comp:GetData("ContextTool.name")[1])
print(prevTool)
if prevTool and prevTool ~= tool then
    print('found prev')
    prevTool.Comments[fu.TIME_UNDEFINED] = ""
end
comp:SetData("ContextTool.name", {tool.Name, contextNo})
print(tool.Name ..' is set as context view #'..contextNo)
tool.Comments = 'Context ' .. contextNo
