------------------------------------------------------------------------------
-- Import Animation from Text File:
-- A powerful script to import keyframes from files where there is one line of data
-- for each frame (space or comma-separated). Can be used to animate 2D point controls
-- or single value sliders. The script tries to be smart by suggesting to animate a tool's
-- Center or Angle property by default, depending on the file's data. Regular
-- paths as well as XY-Paths are supported.
-- You can choose which column of data is used to animate a control, and the frame
-- number where the new keyframes will be pasted to.
-- The file's values can be Fusion's normalized coordinates or they can denote
-- pixels with the origin being at the bottom, top or center. You can also choose
-- to skip a certain number of lines before the first line of data is read.
--
-- This is a tool script!
-- written by Stefan Ihringer, stefan@bildfehler.de
-- based on "Import Boujou Track" by Isaac Guenard
--
-- Version 1.0 - 2010-1101:
-- Ideas: Detect 3D coordinates and import three values automatically
--        Ask to replace existing animation instead of merging keyframes
------------------------------------------------------------------------------
composition = fu:GetCurrentComp()

-----------------------------------------------------
-- trim(strTrim)
-- 
-- returns strTrim with leading and trailing spaces 
-- removed.
-----------------------------------------------------
function trim(strTrim)
	strTrim = string.gsub(strTrim, "^(%s+)", "") -- remove leading spaces
	strTrim = string.gsub(strTrim, "$(%s+)", "") -- remove trailing spaces
	return strTrim
end



------------------------------------------------------------------------------
-- SETUP ---------------------------------------------------------------------
------------------------------------------------------------------------------
INFOTXT = "This script will load keyframes from a text file. It can handle files where there is one line for each frame with values separated by spaces or commas."
PIXELOPTIONS = {"Pixels (zero is bottom/left)", "Pixels (zero is top/left)", "Pixels (zero is image center)", "Fusion (0.5 is image center)"}
PATHOPTIONS = {"XY Path", "PolyLine Path"}

if not tool then
	tool = composition:GetAttrs().COMPH_ActiveTool
	if not tool then
		print("This is a tool script, you must select a tool in the flow to run this script")
		composition:GetFrameList()[1]:SwitchMainView('ConsoleView') 
		exit()
	end
end



------------------------------------------------------------------------------
-- MAIN ----------------------------------------------------------------------
------------------------------------------------------------------------------

fileName = nil
-- build a table of controls that can be animated (Points or Numbers)
controls = {}
controlNames = {}
-- don't show inputs with these IDs in the dialog
filterInputs = {Quality = true, ShutterAngle = true, CenterBias = true, SampleSpread = true,}

inps = tool:GetInputList()
for i, inp in ipairs(inps) do
	local attrs = inp:GetAttrs() 
	-- allow all point inputs but filter numbers to some pre-defined well-known inputs.
	if attrs.INP_External ~= false then
		if attrs.INPS_DataType == "Point" then
			-- todo: mark inputs that are already animated with an asterisk
			table.insert(controlNames, attrs.INPS_Name .. " (2D Point)")
			table.insert(controls, inp)
		elseif attrs.INPID_InputControl == "SliderControl" or attrs.INPID_InputControl == "ScrewControl" then
			if filterInputs[attrs.INPS_ID] ~= true then
				table.insert(controlNames, attrs.INPS_Name)
				table.insert(controls, inp)
			end
		end
	end
end
-- complain if none of the controls have this datatype
if table.getn(controls) == 0 then
   print("Can't find a number or point control that could be animated.")
   composition:GetFrameList()[1]:SwitchMainView('ConsoleView') 
   exit()
end


while fileHandle == nil do
	-- ask the user what text file to process
	dialog = {{"infotxt", Name = "", "Text", Default = INFOTXT, Wrap = true, Lines = 3, ReadOnly = true}}
	if ret == nil then
		table.insert(dialog, {"filename", "FileBrowse", Default = ""})
	else
		table.insert(dialog, {"filename", "FileBrowse", Default = ret.filename})
	end
	
	if err then
		table.insert(dialog, {"warning", Name = "Warning", "Text", Default = err, Wrap = true, Lines = 4, ReadOnly = true})
	end
	
	ret = composition:AskUser("Select a text file containing the animation", dialog)
	if ret == nil then return end
	
	-- can we open the file?
	fileName = composition:MapPath(ret.filename)
	fileHandle, err = io.open(fileName, "r")
end


-- read the first few lines so we can display a preview in the next dialog.
firstDataLine = nil
i = 0
preview = ""
line = fileHandle:read("*l")
while line and (i < 50) do
	-- look for first line that starts with a number (in case we have to skip some initial lines)
	-- and try to detect the number of columns per line
	if firstDataLine == nil and string.find(line, "^%s*-?%d+") then
		firstDataLine = i
		detectColumns = 0
		string.gsub(trim(line), "([^%s,;]+)", function(v) detectColumns = detectColumns + 1 end)
		--print("detected columns in 1st line:", detectColumns)
	end
	preview = preview .. line .. "\n"
	line = fileHandle:read("*l")
	i = i + 1
end
fileHandle:close()
if i == 50 and line ~= nil then
	preview = preview .. "(...)\n"
end
if firstDataLine == nil then
   print("This file doesn't seem to have any data that can be imported.")
   composition:GetFrameList()[1]:SwitchMainView('ConsoleView') 
   exit()
end
-- get filename for text label
string.gsub(fileName, "^.+[/\\](.-)$", function(s) fileNameLabel = s end)


-- set up defaults
ret = {}
ret.skip = firstDataLine
ret.control = 1
if detectColumns == 1 then
	-- If only one column has been detected, default input should be "angle" (if available).
	ret.control = bmd.get_table_index(controlNames, "Angle") or 1
else
	-- If two or more columns have been detected, default input should be "center" (if available).
	ret.control = bmd.get_table_index(controlNames, "Center (2D Point)") or 1
end

-- detect image width, either from tool itself or from comp preferences
compAttrs = comp:GetAttrs()
attrs = tool:GetAttrs()
if attrs.TOOLI_ImageWidth == nil then
	local prefs = composition:GetPrefs()
	ret.width = prefs.Comp.FrameFormat.Width
	ret.height = prefs.Comp.FrameFormat.Height
else
	ret.width = attrs.TOOLI_ImageWidth
	ret.height = attrs.TOOLI_ImageHeight
end

-- show preview dialog. remember: dropdown indices are zero based while LUA tables start with an index of 1.
ret = composition:AskUser("Import Animation", {
	{"preview", Name = "Preview of "..fileNameLabel, "Text", Default = preview, Wrap = true, Lines = 6, ReadOnly = true},
	{"skip", Name = "Lines to skip", "Slider", Integer = true, Default = ret.skip, Min = 0, Max = 50},
	{"column1", Name = "Column of 1st value", "Slider", Integer = true, Default = 1, Min = 1, Max = 10},
	{"column2", Name = "Column of 2nd value (2D points only)", "Slider", Integer = true, Default = 2, Min = 1, Max = 10},
	{"startframe", Name = "Start frame of imported animation", "Slider", Integer = true, Default = compAttrs.COMPN_CurrentTime, Min = compAttrs.COMPN_GlobalStart, Max = compAttrs.COMPN_GlobalEnd},
	{"control", Name = "Apply to:", "Dropdown", Options = controlNames, Default = ret.control - 1},
	{"type", Name = "If 2D, type is:", "Dropdown", Options = PIXELOPTIONS},
	{"path", Name = "If 2D, animate as:", "Dropdown", Options = PATHOPTIONS},
	{"text", Name = "", "Text", Default = "If the text file contains pixel values, you have to specify the image width and height as well, so the values can be converted correctly.", Wrap=true, Lines=3, ReadOnly = true},
	{"width", "Slider", Name="Image Width", Integer=true, Default=ret.width, Min=2, Max=10000},
	{"height", "Slider", Name="Image Height", Integer=true, Default=ret.height , Min=2, Max=10000}
	})

if ret == nil then return end
theControl = controls[ret.control + 1]
is2DPoint = theControl:GetAttrs()["INPS_DataType"] == "Point" or false

-- start reading file for real
fileHandle, err = io.open(fileName, "r")
if fileHandle == nil then
   print(err)
   composition:GetFrameList()[1]:SwitchMainView('ConsoleView') 
   exit()
end

-- skip a number of lines
i = ret.skip
line = fileHandle:read("*l")
while i > 0 do
	line = fileHandle:read("*l")
	i = i - 1
end

-- collect values in this array
values = {}
i = 0
while line do
	line = trim(line)
	if string.sub(line, 1, 1) ~= "#" then
		values[i] = {}
		string.gsub(line, "([^%s,;]+)", function(v) table.insert(values[i], tonumber(v)) end)
		if #values[i] > 0 then
			i = i + 1
		end
	end
	line = fileHandle:read("*l")
end
fileHandle:close()
fileHandle = nil


composition:StartUndo("Import Animation on "..attrs.TOOLS_Name..":"..controlNames[ret.control + 1])

-- is the control animated?
deleteKeyAt = nil
-- todo: ask to replace values
if theControl:GetAttrs().INPB_Connected == true then
	local ret = composition:AskUser(theControl:GetAttrs().INPS_Name .. " is animated!", {
		{"warning", Name = "warning", "Text", Default="The selected control is already animated or connected to another control."..
		"\n\nSelect OK to continue anyway, or CANCEL to abort. If you select OK the keys in the track file will be merged with existing keys.", Wrap=true, Lines=8}
		})
	if ret == nil then
		composition:EndUndo(false)
		exit()
	end
else
	if is2DPoint then
		if ret.path == 0 then
            tool:AddModifier(theControl.ID, "XYPath")
		else
            print("Currently unable to add Path() modifier")
            -- this should work, but it does't unfortunately:
            -- tool:AddModifier(theControl.ID, "Path")
            tool:AddModifier(theControl.ID, "XYPath")
		end
	else
        tool:AddModifier(theControl.ID, "BezierSpline")
	end
	-- a keyframe is created at the current time. It needs to be deleted
	-- if it isn't overwritten by imported data
	deleteKeyAt = comp:GetAttrs().COMPN_CurrentTime
end


--finally do the keyframes
if composition.UpdateMode then
	if composition.UpdateMode == "None" or composition.UpdateMode == "Some" then
		hold = composition.UpdateMode
		composition.UpdateMode = "All"
	end
end

-- set up default coordinate if user requested a column that doesn't exist or
-- some values could not be converted to a number
defaultCoordinate = ret.type == 3 and 0.5 or 0
for f, coord in pairs(values) do
	local frame = tonumber(f) + ret.startframe
	if is2DPoint == true then
		local x = tonumber(coord[ret.column1] or defaultCoordinate)
		local y = tonumber(coord[ret.column2] or x)
		-- convert pixel values if data isn't already Fusion's normalized coordinates
		if ret.type == 0 then
			-- pixels bottom/left
			x = x / ret.width
			y = y / ret.height
		elseif ret.type == 1 then
			-- pixels top/left
			x = x / ret.width
			y = 1 - y / ret.height
		elseif ret.type == 2 then
			-- pixels centered
			x = x / ret.width + 0.5
			y = y / ret.width + 0.5
		end
		theControl[frame] = {x, y}
	else
		local x = tonumber(coord[ret.column1] or 0)
		theControl[frame] = x
	end
	-- delete frame that might have been created automatically when the control was animated
	if deleteKeyAt ~= nil then
		if deleteKeyAt ~= frame then
			theControl[deleteKeyAt] = nil
		end
		deleteKeyAt = nil
	end
end

print("Imported "..#values.." keys to "..tool:GetAttrs().TOOLS_Name..":"..theControl:GetAttrs().INPS_Name)
composition:EndUndo(true)
if hold then composition.UpdateMode = hold end

