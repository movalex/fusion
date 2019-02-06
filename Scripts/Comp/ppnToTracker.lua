
ct = comp.CurrentTime

-- get selected Tools (should be 2 in this case. Tracker and PPn)
selTools = comp:GetToolList(true)
for t, tool in pairs(selTools) do
	if tool:GetAttrs().TOOLS_RegID == "Tracker" then trk = tool end
	if tool:GetAttrs().TOOLS_RegID == "PerspectivePositioner" then ppn = tool end
end

corners = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
-- assuming you're using TrackedCenter[1,2,3,4] for Corner[TopLeft, TopRight, BottomLeft, BottomRight]
trackers = {1,2,3,4}

if trk and ppn then
	trkName = trk:GetAttrs().TOOLS_Name
	-- ppn.TopLeft:SetExpression(trkName .. ".TrackedCenter1")
	for n = 1, 4 do
		ppn[corners[n]]:SetExpression(trkName .. ".TrackedCenter"..n)
	end
else
	print("Tracker and ppn not found!")
    end
