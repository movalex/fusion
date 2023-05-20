local ctrls = table.ordered()

comp:Lock()
ctrls.SOLO = {
    LINKID_DataType = "Number",
    INP_Default = 0,
    INPID_InputControl = "ButtonControl",
    BTNCS_Execute = [[    function check_selected(tool)
    return tool:GetAttrs('TOOLB_Selected')
end

function check_enabled(tool)
    return tool:GetAttrs('TOOLB_PassThrough')
end
    local cmp = fu:GetCurrentComp()
    local selectedSavers = cmp:GetToolList(true, "Saver")
    local allSavers = cmp:GetToolList(false, "Saver")
    for _, currentSaver in pairs(allSavers) do
        if not check_selected(currentSaver) then
            currentSaver:SetAttrs( { TOOLB_PassThrough = true } )
        end
    end
    for _, sel in pairs(selectedSavers) do
        if check_enabled(sel) then
            sel:SetAttrs({ TOOLB_PassThrough = false})
        end
    end ]],
    LINKS_Name = "Solo",
    ICS_ControlPage = "File",
}
ctrls.ML = {
    LINKID_DataType = "Number",
    INP_Default = 0,
    INPID_InputControl = "ButtonControl",
    BTNCS_Execute = [[ tool = comp.ActiveTool; comp:RunScript("Scripts:Comp/Saver Tools/LoaderFromSaver.lua", tool) ]],
    LINKS_Name = "Make Loader",
    ICS_ControlPage = "File",
}
tool.UserControls = ctrls
refresh = tool:Refresh()


function unlock(cmp)
    cmp:Unlock()
    print('comp unlocked')
    if cmp:IsLocked() then
        unlock(cmp)
    end
end

unlock(comp)
