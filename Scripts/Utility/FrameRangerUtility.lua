comp = fu:GetCurrentComp()
function getBounds()
    compAttrs = comp:GetAttrs()
    rStart = compAttrs.COMPN_RenderStart
    rEnd = compAttrs.COMPN_RenderEnd
    return rStart, rEnd
end

function minusOffset(offset, s, e)
    comp:SetAttrs({COMPN_RenderStart = s + offset})
    comp:SetAttrs({COMPN_RenderEnd = e - offset})
end

function plusOffset(offset, s, e)
    comp:SetAttrs({COMPN_RenderStart = s - offset})
    comp:SetAttrs({COMPN_RenderEnd = e + offset})
end

function main()
    status = comp:GetData("FR.set")
    s, e = getBounds()
    currentOffset = comp:GetData("FR.offset") or 24
    if status == nil then
        minusOffset(currentOffset, s, e)
        comp:SetData("FR.set", "minus")
        return
    end
    if status == 'plus' then
        minusOffset(currentOffset, s, e) 
        comp:SetData("FR.set", "minus")
    else
        local gStart = comp:GetAttrs().COMPN_GlobalStart
        if s == gStart then
            minusOffset(currentOffset, s, e) 
            comp:SetData("FR.set", "plus")
            return
        end
        plusOffset(currentOffset, s, e)
        comp:SetData("FR.set", "plus")
    end
end
main()
