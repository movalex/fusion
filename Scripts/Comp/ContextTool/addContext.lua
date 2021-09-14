comp = fu:GetCurrentComp()
tool = comp.ActiveTool or comp:GetToolList(true)[1] 

if not tool then
    print ('no tool selected')
    return
end

data = comp:GetData("ContextTool.contexts")

function SetContext(data)
    if not data then
        return 1
    end
    if data and not CONTEXT then
        CONTEXT = #data + 1
    end
    if CONTEXT > 9 then
        CONTEXT = 9
    end
    return CONTEXT
end

if not CONTEXT then
    CONTEXT = SetContext(data)
end

local currentComment = tool.Comments[1]

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

matchComment = currentComment:match("_CONTEXT_")
if matchComment then
    tool.Comments = currentComment:gsub("(_CONTEXT_ )%d", "%1" .. CONTEXT)
else
    tool.Comments = '_CONTEXT_ ' .. CONTEXT .."\n" .. currentComment
end

data[CONTEXT] = tool.Name
comp:SetData("ContextTool.contexts", data)

print(tool.Name ..' is set as context view #'..CONTEXT)
weirdPurpleColor = {R = 1, G = 0, B = 1}
tool.TileColor = weirdPurpleColor
