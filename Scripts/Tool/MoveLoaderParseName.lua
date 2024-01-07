
local function ParseFilename(filename)
    local seq = {}
    seq.FullPath = filename
    string.gsub(seq.FullPath, "^(.+[/\\])(.+)", function(path, name)
        seq.Path = path
        seq.FullName = name
    end)
    string.gsub(seq.FullName, "^(.+)(%..+)$", function(name, ext)
        seq.Name = name
        seq.Extension = ext
    end)
    -- check if no extension
    if not seq.Name then
        seq.Name = seq.FullName
    end
    
    string.gsub(seq.Name, "^(.-)(%d+)$", function(name, SNum)
        seq.CleanName = name
        seq.SNum = SNum
    end)
    
    if seq.SNum then
        seq.Number = tonumber(seq.SNum)
        seq.Padding = string.len(seq.SNum)
    else
        seq.SNum = ""
        seq.CleanName = seq.Name
    end
    
    if seq.Extension == nil then
        seq.Extension = ""
    end
    return seq 
end


function moveLoader(tool)
    if tool.ID ~= "Loader" then
        print('This is not a Loader tool')
        return nil
    end
    globalStart = comp:GetAttrs().COMPN_GlobalStart
    inPoint = comp:GetAttrs().COMPN_RenderStart
    comp:StartUndo('Move Loader')
    
    clipName = tool.Clip[1]

    if inPoint == globalStart then
        inPoint = ParseFilename(clipName).Number
    end
    bmd.MoveClip(tool, globalStart, tonumber(inPoint))
    comp:EndUndo()
end


moveLoader(tool)

