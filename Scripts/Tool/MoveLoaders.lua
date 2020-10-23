function moveLoader(tool, startFrom)
    if tool.ID ~= "Loader" then
        print('this is not a Loader tool')
        return nil
    end
    comp:StartUndo('set loader start')
    bmd.MoveClip(tool, comp:GetAttrs().COMPN_GlobalStart, tonumber(startFrom))
    comp:EndUndo()
end

newStart = comp:GetData("FrameHandles.offset") or 24
inPoint = comp:GetAttrs().COMPN_RenderStart

if newStart < inPoint then
    newStart = inPoint
end

moveLoader(tool, newStart)
