comp:Lock()
local selectedSavers = comp:GetToolList(true, "Saver")
local allSavers = comp:GetToolList(false, "Saver")
    for i, currentSaver in pairs(allSavers) do
        local isSelected = false
        for j, currentSelectedSaver in pairs(selectedSavers) do
            if(currentSaver == currentSelectedSaver) then
            isSelected = true
        end
    end
    if isSelected == false then
        currentSaver:SetAttrs( { TOOLB_PassThrough = true } )
    end
end
comp:Unlock()