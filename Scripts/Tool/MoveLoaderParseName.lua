function ParseInPoint(loader)
    local parsedName = bmd.parseFilename(loader.Clip[1])
    return parsedName.Number
end


function moveLoader(tool, startFrom)
    if tool.ID ~= "Loader" then
        print('this is not a Loader tool')
        return nil
    end
    comp:StartUndo('set loader start')
    bmd.MoveClip(tool, comp:GetAttrs().COMPN_GlobalStart, tonumber(startFrom))
    comp:EndUndo()
end

inPoint = comp:GetAttrs().COMPN_RenderStart
parsedInPoint = ParseInPoint(tool)
-- newStart = comp:GetData("FrameHandles.offset")

moveLoader(tool, parsedInPoint)

