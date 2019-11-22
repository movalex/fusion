comp:StartUndo('set loader start')
for i, tool in ipairs(comp:GetToolList(true), "Loader") do
    bmd.MoveClip(tool, comp:GetAttrs().COMPN_GlobalStart, 1)
end
comp:EndUndo()

