if not comp then
    comp = fu:GetCurrentComp()
end

function setTime()
    local state = comp:GetData("Ranger.tempIsSet")
    if state == nil then
        state = false
    end
    if state == false then
        renderEnd = comp:GetAttrs().COMPN_RenderEnd 
        comp:SetData("Ranger.before", renderEnd) 
        comp:SetAttrs({COMPN_RenderEnd = comp.CurrentTime})
        state = true
        print('temp set ', comp.CurrentTime)
        comp:Play()
    else
        restoreTime = comp:GetData("Ranger.before")
        comp:SetAttrs({COMPN_RenderEnd = restoreTime})
        comp:SetData("Ranger.before", restoreTime) 
        state = false
        print('position restored ', restoreTime)
        comp.CurrentTime = comp:GetAttrs().COMPN_RenderStart
        comp:Play()
    end
    return state
end

local state = setTime()
comp:SetData("Ranger.tempIsSet", state)
