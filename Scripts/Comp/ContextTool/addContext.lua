function has_key(tab, key)
    for k,v in ipairs(tab) do
        if k == key then
            return true
        end
    end
    return false
end

addComment = false

tool = comp.ActiveTool or comp:GetToolList(true)[1] 

if not tool then
    print ('no tool selected')
    return
end

data = comp:GetData("ContextTool.contexts")

if data and not CONTEXT then
    for i = 1, 9 do
        if has_key(data, i) then
            CONTEXT = i + 1
        end
        if CONTEXT > 9 then
            CONTEXT = 9
        end
    end
end

local comment = tool.Comments[1]

if data then
    local dataToolName = data[CONTEXT]
    local toolFromData = comp:FindTool(dataToolName)
    if toolFromData then
        toolComment = toolFromData.Comments[1]
        if toolFromData ~= tool then
            toolFromData.TileColor = nil
            toolFromData.Comments = toolComment:gsub("_CONTEXT_ %d\n", "")
        else
            toolFromData.Comments = toolComment:gsub("(_CONTEXT_) %d", "%1 "..CONTEXT)
        end
    end
    for i, name in ipairs(data) do
        if name == tool.Name and i ~= CONTEXT then
            table.remove(data, i)
        end
    end
else
    data = {}
end

mm = comment:match("_CONTEXT_")
if mm then
    tool.Comments = comment:gsub("(_CONTEXT_ )%d", "%1" .. CONTEXT)
else
    tool.Comments = '_CONTEXT_ ' .. CONTEXT .."\n" .. comment
end

data[CONTEXT] = tool.Name
comp:SetData("ContextTool.contexts", data)

print(tool.Name ..' is set as context view #'..CONTEXT)
purpleColor = {R = 1, G = 0, B = 1}
tool.TileColor = purpleColor
