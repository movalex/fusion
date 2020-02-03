START_FRAME = 1
comp:StartUndo('set loader start')
for i, tool in ipairs(comp:GetToolList(true), "Loader") do
    print(tool.Name .. " " .. "global start is set to " .. START_FRAME)
    bmd.MoveClip(tool, comp:GetAttrs().COMPN_GlobalStart, START_FRAME)
end
comp:EndUndo()

