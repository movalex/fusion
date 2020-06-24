if not tool then
    print('this is a tool script, it should be run from a flow context menu')
end

function moveLoader(tool, startFrom)
    if tool.ID ~= "Loader" then
        print('this is not a Loader tool')
        return nil
    end
    comp:StartUndo('set loader start')
    bmd.MoveClip(tool, comp:GetAttrs().COMPN_GlobalStart, startFrom)
    comp:EndUndo()
end

if tool.ID == "Loader" then
    tool.PixelAspect = 2
    tool.CustomPixelAspect = {1,1}
end
