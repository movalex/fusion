
--###################################
-- a little tool script that increases 
-- the version count on Loaders and Savers
--
-- michael vorberg (mv@empty98.de)
-- 17 Aug 2008
-- 17. October 2017 update to Fusion9 and maybe more robust pattern search
--######################################
fusion = Fusion()

composition = fusion:GetCurrentComp()


if not tool then
	print("Error: This script must be run as a Tool Script.")
	return
end
comp.Lock()
if (tool:GetAttrs().TOOLS_RegID == "Saver") or (tool:GetAttrs().TOOLS_RegID == "Loader") then
	-- get saver's output location
	output_old = tool.Clip[fu.TIME_UNDEFINED]
	if output_old == "" then
		local err = "This script can only update the render location if an output filename has already been specified."
		comp:AskUser("Error", {{"", "Text", ReadOnly=true, Default=err, Wrap=true, Lines=2}})
		return
	end
	if (tool:GetAttrs().TOOLS_RegID == "Loader") then
		old_globalIn = tool.GlobalIn[fu.TIME_UNDEFINED]
		old_globalOut = tool.GlobalOut[fu.TIME_UNDEFINED]
		old_ClipStart = tool.ClipTimeStart[fu.TIME_UNDEFINED]
		old_ClipEnd = tool.ClipTimeEnd[fu.TIME_UNDEFINED]
		oldLastFrame = tool.HoldLastFrame[fu.TIME_UNDEFINED]
		
	end
	version_find = string.match(output_old, '[Vv]%d+')
	version_prefix = string.sub(version_find, string.find(version_find, '[Vv]'), string.find(version_find, '[Vv]'))
	version_old_number = string.match(version_find, '%d+')
	version_padding = string.len(version_old_number)
	version_new_number = tonumber(version_old_number)+1
	output_new = string.gsub(output_old, version_prefix..version_old_number, version_prefix..string.format("%0"..version_padding.."d",version_new_number))

	composition:StartUndo("Update Render Location")
	tool:SetAttrs({TOOLB_PassThrough = true})
	tool.Clip[fu.TIME_UNDEFINED] = output_new
	if (tool:GetAttrs().TOOLS_RegID == "Loader") then
		tool.GlobalOut[fu.TIME_UNDEFINED] = old_globalOut
		tool.GlobalIn[fu.TIME_UNDEFINED] = old_globalIn
		tool.ClipTimeEnd[fu.TIME_UNDEFINED] = old_ClipEnd
		tool.ClipTimeStart[fu.TIME_UNDEFINED] = old_ClipStart
		tool.HoldLastFrame[fu.TIME_UNDEFINED] = oldLastFrame
	end
	tool:SetAttrs({TOOLB_PassThrough = false})
	composition:EndUndo(true)

	print("\nUpdate Render Location successful for "..tool:GetAttrs().TOOLS_Name)
	print("old output: "..output_old)
	print("new output: "..output_new)
	print()
else
	local err  = "This script can only be run on a Saver or Loader tool."
	comp:AskUser("Error", {{"", "Text", ReadOnly=true, Default=err, Wrap=true, Lines=1}})
	return
end
comp.Unlock()
