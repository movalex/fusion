-- get selected Tools (should be 2 in this case. Tracker and PPn)
selTools = comp:GetToolList(true)
for t, tool in pairs(selTools) do
	if tool:GetAttrs().TOOLS_RegID == "Tracker" then trk = true end
	if tool:GetAttrs().TOOLS_RegID == "PerspectivePositioner" then ppn = true end
end

corners = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
-- create list of Sizes to get trackers number
trackers = {}
if trk and ppn then
    -- should be 4 trackers for ppn
    for _, s in ipairs(trk:GetInputList()) do
        if string.find(s:GetAttrs().INPS_ID, "Sizes")
            then table.insert(trackers, s)
        end
    end
    print('Found ' .. #trackers .. ' trackers')
    if #trackers == 4 then
        trkName = trk:GetAttrs().TOOLS_Name
        -- ppn.TopLeft:SetExpression(trkName .. ".TrackedCenter1")
        for n = 1, #trackers do
                ppn[corners[n]]:SetExpression(trkName .. ".TrackedCenter"..n)
        end
    end
else
	print("Tracker and ppn not found!")
    end
