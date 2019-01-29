------------------------------------------------------------------------------
-- Export Animation to AfterEffects: Exports keyframes to AfterEffects
-- This is a tool script!
-- written by Stefan Ihringer, stefan@bildfehler.de
--
-- This script converts an animated input of the current tool to text data that
-- can be copy&pasted into AfterEffects (CS3 and above). You can export number
-- and point controls to position, anchor, scale, opacity or rotation.
-- version 1.2, 2019-01-19: support for Fusion 9
-- version 1.1, 2011-05-13: support for 3D transforms
-- version 1.0, 2011-01-06
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- SETUP ---------------------------------------------------------------------
------------------------------------------------------------------------------

if not tool then
	tool = composition.ActiveTool
	if not tool then
		print("This is a tool script, you must select a tool in the flow to run this script")
		return
	end
end

controlNames = {}   -- saves the names of animated inputs

for key, inp in ipairs(tool:GetInputList()) do
	local attrs = inp:GetAttrs()
	if attrs.INPB_Connected then
		local datatype = inp:GetConnectedOutput():GetAttrs().OUTS_DataType
		if datatype == "Point" or datatype == "Number" then
			table.insert(controlNames, attrs.INPS_ID)
		end
	end
end

if table.getn(controlNames) == 0 then
	print("No valid animated controls found on this tool.")
	return
end

-- AfterEffects properties that can be animated and their respective column headers
targetlist = {"Position", "Anchor Point", "Point of Interest", "Scale", "Rotation", "Opacity"}
columnheaders = {"X pixels\tY pixels\tZ pixels",
                 "X pixels\tY pixels\tZ pixels",
                 "X pixels\tY pixels\tZ pixels",
                 "X percent\tY percent\tZ percent",
                 "degrees",
                 "percent",
                 }

compattrs = composition:GetAttrs()
compprefs = composition:GetPrefs("Comp.FrameFormat")
ret = {}
ret.from = compattrs.COMPN_RenderStart
ret.to = compattrs.COMPN_RenderEnd

-- image width and height, autodetected from active tool. If this is not possible (tool hasn't
-- been rendered yet), use the comp defaults.
imageWidth = tool:GetAttrs().TOOLI_ImageWidth or compprefs.Width
imageHeight = tool:GetAttrs().TOOLI_ImageHeight or compprefs.Height

-- header for output data
data =
	"Adobe After Effects 8.0 Keyframe Data\n\n"..
	"\tUnits Per Second\t" .. compprefs.Rate .. "\n"..
	"\tSource Width\t" .. imageWidth .. "\n"..
	"\tSource Height\t" .. imageHeight .. "\n"..
	"\tSource Pixel Aspect Ratio\t" .. compprefs.AspectX .. "\n"..
	"\tComp Pixel Aspect Ratio\t" .. compprefs.AspectX .. "\n\n"

-- display dialog
msg = "Select the animated input you want to convert. Smooth Bezier handles will NOT be converted correctly. Use the Bake Animation option in this case."
ret = composition:AskUser("Export to AfterEffects", {
	{ "info", "Text", Name = "", ReadOnly = true, Lines = 4, Wrap = true, Default = msg },
	{ "input", "Dropdown", Name = "Input", Options = controlNames },
	{ "target", "Dropdown", Name = "AE Property", Options = targetlist },
	{ "from", "Slider", Name = "Start frame", Integer = true, Default = ret.from, Min = compattrs.COMPN_GlobalStart, Max = compattrs.COMPN_GlobalEnd },
	{ "to", "Slider", Name = "End frame", Integer = true, Default = ret.to, Min = compattrs.COMPN_GlobalStart, Max = compattrs.COMPN_GlobalEnd },
	{ "bake", "Checkbox", Name = "Bake Animation (create keys on all frames)", Default = 1, NumAcross = 2 },
})


------------------------------------------------------------------------------
-- MAIN ----------------------------------------------------------------------
------------------------------------------------------------------------------

if ret then
	if ret.to > ret.from then
		from = ret.from
		to = ret.to
	else
		from = ret.to
		to = ret.from
	end

	inp = tool[controlNames[ret.input+1]]
	-- if a one-dimensional input gets exported to a 2D property (position/anchor), the same value is used for both dimensions
	is2D = (inp:GetConnectedOutput():GetAttrs().OUTS_DataType == "Point")
	-- is input part of a Transform3DOp? If so, determine the 3 coordinate inputs that belong together
	whichTransform = string.match(controlNames[ret.input+1], "^Transform3DOp%.(%a+)%.[XYZ]$")
	inps3D = {}
	if whichTransform ~= nil then
		is3D = true
		if targetlist[ret.target + 1] == "Rotation" then is3DRotation = true end
		print(whichTransform)
		inps3D[1] = tool["Transform3DOp."..whichTransform..".X"]
		inps3D[2] = tool["Transform3DOp."..whichTransform..".Y"]
		inps3D[3] = tool["Transform3DOp."..whichTransform..".Z"]
	end
		
	-- append another header describing the data
	data = data .. "Transform\t" .. targetlist[ret.target + 1] .. "\n\tFrame\t" .. columnheaders[ret.target + 1] .. "\t\n"
	
	-- 3D rotations are saved as three different transforms. These additional headers are only appended if a Transform3DOp is
	-- exported as a rotation property!
	dataXRot = "\nTransform\tX Rotation\n\tFrame\tdegrees\n"
	dataYRot = "\nTransform\tY Rotation\n\tFrame\tdegrees\n"

	-- helper function that converts Fusion's normalized coordinates to AfterEffects pixel coordinates or to a percentage scale (0..100)
	function convert(x, factor)
		return string.format("%.3f", x * factor)
	end
	
	-- helper function that returns a single tab-separated line of data, depending on the AfterEffects property to be exported
	-- accesses globals inp, is2D, imageWidth and imageHeight
	function format_line(frame,aeProperty)
		local xval = is2D and inp[frame][1] or inp[frame]
		local yval = is2D and inp[frame][2] or xval
		local zval = 0
		
		-- handle 3D tuples
		if is3D then
			xval = inps3D[1][frame]
			yval = inps3D[2][frame]
			zval = inps3D[3][frame]
		end

		local tmp = "\t" .. frame .. "\t"
		if aeProperty == "Position" or aeProperty == "Anchor Point" then
			-- todo: scale of coordinates in AfterEffects 3D space might be wrong. No chance to test this yet...
			tmp = tmp .. convert(xval, imageWidth) .. "\t" .. convert(yval, imageHeight) .. "\t" .. convert(zval, imageWidth) .. "\t"
		elseif aeProperty == "Scale" then
			tmp = tmp .. convert(xval, 100) .. "\t" .. convert(yval, 100) .. "\t" .. convert(zval, 100) .. "\t"
		elseif aeProperty == "Rotation" then
			-- for 3D, rotation is z rotation
			if is3D then
				tmp = tmp .. convert(zval, 1) .. "\t"
			else
				tmp = tmp .. convert(xval, 1) .. "\t"
			end
		elseif aeProperty == "X Rotation" then
			tmp = tmp .. convert(xval, 1) .. "\t"
		elseif aeProperty == "Y Rotation" then
			tmp = tmp .. convert(yval, 1) .. "\t"
		elseif aeProperty == "Opacity" then
			tmp = tmp .. convert(xval, 100) .. "\t"
		end
		tmp = tmp .. "\n"
		return tmp
	end
	
	composition:Lock()
	if ret.bake == 0 then
		-- smart loop (only converts existing keyframes)
		keys = inp:GetKeyFrames()
		for _, f in keys do
			-- skip extra keyframe at -1000000 that turns up first
			if f ~= -1000000 and f >= from and f <= to then
				data = data .. format_line(f, targetlist[ret.target + 1])
				-- if 3D rotation is exported, fill the additional chunks for X and Y rotation
				if is3DRotation then
					dataXRot = dataXRot .. format_line(f, "X Rotation")
					dataYRot = dataYRot .. format_line(f, "Y Rotation")
				end
			end
		end
	else
		-- dumb loop (bakes animation)
		for f = from, to do
			data = data .. format_line(f, targetlist[ret.target + 1])
			-- if 3D rotation is exported, fill the additional chunks for X and Y rotation
			if is3DRotation then
				dataXRot = dataXRot .. format_line(f, "X Rotation")
				dataYRot = dataYRot .. format_line(f, "Y Rotation")
			end
		end
	end
	composition:Unlock()	
	
	-- append X and Y rotation chunks?
	if is3DRotation then
		data = data .. dataXRot .. dataYRot
	end
	
	-- end data
	data = data .. "\n\nEnd of Keyframe Data\n"
	
	-- display data
	ret = composition:AskUser("Click OK to copy to clipboard:", {
		{"data", "Text", Name = "Copy and paste this to AfterEffects:", ReadOnly = true, Lines = 15, Default = data, },
		})
	if ret ~= nil then
		eyeon.setclipboard(data)
	end
end

