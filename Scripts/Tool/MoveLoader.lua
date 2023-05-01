-- tool script to move the Loader to start from the RenderIn position

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
-- inPoint = comp:GetData("FrameHandles.offset")

moveLoader(tool, inPoint)
