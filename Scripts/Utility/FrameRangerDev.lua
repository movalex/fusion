target = fu:GetCurrentComp()

function minusOffset(offset, s, e)
    target:SetAttrs({COMPN_RenderStart = s + offset})
    target:SetAttrs({COMPN_RenderEnd = e - offset})
    target:SetData("FrameHandles.set", "true")
end

function getBounds()
    rStart = compAttrs.COMPN_RenderStart
    rEnd = compAttrs.COMPN_RenderEnd
    return rStart, rEnd
end

function resetRange()
    target:SetAttrs({COMPN_RenderStart = gStart})
    target:SetAttrs({COMPN_RenderEnd = gEnd})
    target:SetData("FrameHandles.set", false)
    return false
end

function main()
    compAttrs = target:GetAttrs()
    gStart = compAttrs.COMPN_GlobalStart
    gEnd = compAttrs.COMPN_GlobalEnd
    target:StartUndo("SetHandles")
    local status = target:GetData("FrameHandles.set")
    local s, e = getBounds()
    currentOffset = target:GetData("FrameHandles.offset") or 24
    if status == nil then
        resetRange()
        minusOffset(currentOffset, s, e)
    end
    if status == 'false' then
        if s > gStart or e < gEnd then
            resetRange()
            s = gStart
            e = gEnd
        end
        minusOffset(currentOffset, s, e)
    else
        resetRange()
        target:SetData("FrameHandles.set", "false")
    end
    target:EndUndo()
end
main()
