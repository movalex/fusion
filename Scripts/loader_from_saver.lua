savers = comp:GetToolList(true, 'Saver')

if (#savers) == 0 then
    print('select saver tool first')
else
    comp:Lock()
    local flow = comp.CurrentFrame.FlowView
    for n, tool in ipairs(savers) do
        x, y = flow:GetPos(tool)
        selected_clipname = tool:GetAttrs()["TOOLST_Clip_Name"][1]
        local loader = comp:Loader({Clip = selected_clipname})
        flow:SetPos(loader, x+1, y)
    end
    comp:Unlock()
end