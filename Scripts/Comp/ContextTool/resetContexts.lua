comp = fu:GetCurrentComp()

local data = comp:GetData("ContextTool.contexts")
if not data then
    return
end
for i, tool in pairs(data) do
    tool = comp:FindTool(tool)
    tool.TileColor = nil
    local toolComment = tool.Comments[1]
    tool.Comments = toolComment:gsub("_CONTEXT_ %d\n", "")
end

comp:SetData("ContextTool")
