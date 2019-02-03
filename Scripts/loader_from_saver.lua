savers = comp:GetToolList(true, 'Saver')

if (#savers) == 0 then
    print('select saver tool first')
else
    comp:Lock()
    local flow = comp.CurrentFrame.FlowView
    for n, tool in ipairs(savers) do
        x, y = flow:GetPos(tool)
        selected_clipname = tool:GetAttrs()["TOOLST_Clip_Name"][1]
        seq = string.match(selected_clipname, '(%d+)%..+$')
        -- if pattern 0000.ext$ is found set selected name
        -- otherwice replace extention with 0000-extention
        if seq then
            local loader = comp:Loader({Clip = selected_clipname})
            flow:SetPos(loader, x+1, y)
        else
            name, ext = string.match(selected_clipname,'([^/]-([^.]+))$')
            new_name = selected_clipname:gsub('.'..ext, '0000.'..ext)
            local loader = comp:Loader({Clip = new_name})
            flow:SetPos(loader, x+1, y)
        end
    end
    comp:Unlock()
end

