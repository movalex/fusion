if not comp.ActiveTool then
    print('select tool first')
else
    composition:Lock()
    local flow = comp.CurrentFrame.FlowView
    local x, y = flow:GetPos(comp.ActiveTool)
    selected = comp.ActiveTool:GetAttrs()["TOOLST_Clip_Name"][1]
    local loader = comp:Loader ({Clip = selected})
    flow:SetPos(loader, x+1, y)
    composition:Unlock()
end