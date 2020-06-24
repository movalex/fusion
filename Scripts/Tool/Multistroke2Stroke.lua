if tool:GetID() ~= "Multistroke" and tool:GetID() ~= "CloneMultistroke" and tool:GetID() ~= "Paint" then
	print("This script only works with Paint multistrokes")
	return
end

print("Converting multistroke:")

-- TODO: calc average x,y for centre?
function GetPoints(tbl)
	local pts = {}
	local i, pt

	for i, pt in ipairs(tbl) do
		pts[i] = {}
		pts[i].X = pt.X
		pts[i].Y = pt.Y
		pts[i].Time = pt.T
		pts[i].Pressure = pt.Pressure
	end
	
	return pts
end

function MergeStrokeParams(dest, src)
	local key, val
	for key, val in pairs(src) do
		if type(val) == "table" then
			if type(dest[key]) ~= "table" then
				dest[key] = {}
			end
			MergeStrokeParams(dest[key], val)
		else
			dest[key] = val
		end
	end
end

function CopyTable(tbl)
	local i,v,ret
	ret = {}  
	for i,v in pairs(tbl) do
		if type(v) == "table" then  
			ret[i] = CopyTable(v)  
		else  
			ret[i] = v  
		end  
	end  
	return ret  
end  

local tbl = tool:SaveSettings()

if tool:GetID() == "Paint" then
	-- find first selected multistroke	
	for name, t in pairs(tbl.Tools) do
		if type(t) == "table" and (t.__ctor == "Multistroke" or t.__ctor == "CloneMultistroke") then
			if comp[name]:GetAttrs().TOOLB_Selected then
				msname = name
				mstool = comp[msname]
				break
			end
		end
	end
else
	mstool = tool
	msname = mstool:GetAttrs().TOOLS_Name
end

if mstool == nil then
	print("Error: No multistroke found")
	return
end

local mstbl = tbl.Tools[msname]
local strokes = mstbl.Strokes
local firsttool, lasttool
local starttime = 0.0
local endtime = 1.0
local chain = {}
local params = 
  {
	  StrokeAnimation = { __ctor = "Input", Value = 0, },
      -- Duration        = { __ctor = "Input", Value = 360, },
  }

-- Build a table of a bunch of Strokes from the multistroke table

comp:StartUndo("Convert Multistroke")

local num = 1
firsttool = msname.."_Stroke"..num

while strokes[num] do
	local key,val

	local name = msname.."_Stroke"..num
	print("   Creating ".. name)
	
	-- copy the current params
	if type(strokes[num].Params) == "table" then
		MergeStrokeParams(params, strokes[num].Params)
	end

    compAttrs = comp:GetAttrs()
    endRange = compAttrs.COMPN_RenderEnd
	if strokes[num].Time then
		starttime = strokes[num].Time
		-- endtime = starttime + 1.0
        endtime = endRange + 1
	end
	if strokes[num].Frames then
		endtime = starttime + strokes[num].Frames
	end
	
	chain[name] =
	{ 
		__ctor = "Stroke",
		Points = GetPoints(strokes[num]),
		IsThreaded = (num % 30 == 0),
		Brushes = { [0] = "SoftBrush" },
		ApplyModes = { [0] = "PaintApplyColor" },
		EnabledRegion = { __ctor = "TimeRegion", { Start = starttime, End = endtime - 0.0001, }, },
	}

	local inpvals = {}                  -- gotta construct a new table each time
	for key,val in pairs(params) do
		if type(val) == "table" then
			inpvals[key] = CopyTable(val)
		else
			inpvals[key] = val
		end
		inpvals[key]["__ctor"] = "Input"
	end
	chain[name].Inputs = inpvals

	if lasttool then
		chain[name].Inputs.Paint = 
			{
				__ctor = "Input", 
				SourceOp = lasttool, 
				Source = "Out",
			}
	end

	lasttool = name
	num = num + 1;
end

comp:Lock()

-- Add it to the comp
comp:Paste( { Tools = chain } )
-- and connect it up
local firststroke = comp[firsttool]
local srcout = mstool.Paint:GetConnectedOutput()
if srcout and firststroke then
	firststroke.Paint:ConnectTo(srcout)
end

local laststroke = comp[lasttool]
local inps = mstool.Out:GetConnectedInputs()
if inps[1] and laststroke then
	local ok = inps[1]:ConnectTo(laststroke.Out)	-- will probably delete 'mstool'
end

-- Also have to connect any external links
for tname,t in pairs(chain) do
	for iname, inp in pairs(t.Inputs) do
		if inp.SourceOp then
			local comp_t = comp[tname]
			if comp_t then
				local comp_inp = comp_t[iname]
				if comp_inp and not comp_inp:GetConnectedOutput() then
					local dest_t = comp[inp.SourceOp]
					if dest_t then
						comp_inp:ConnectTo(dest_t[inp.Source])
--						print("Connected "..tname.."."..iname.." to "..inp.SourceOp.."."..inp.Source)
					end
				end
			end
		end
	end
end

comp:Unlock()

comp:EndUndo(true)

print("Done ".. num-1 .. " strokes.")
