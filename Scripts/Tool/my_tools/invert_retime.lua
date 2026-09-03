--[[--
Invert Retime
Mirrors an animated TimeStretcher's SourceTime curve onto the SpeedWarp's Delay.
Install: Scripts/Tool/Invert Retime.lua
Usage:   right-click the SpeedWarp > Scripts > Invert Retime
--]]--

local comp = fu:GetCurrentComp()
local dst = tool or comp.ActiveTool
tool.Speed = 0

-- animated TimeStretchers only
local found = {}
for _, t in ipairs(comp:GetToolList(false, "TimeStretcher")) do
	local out = t.SourceTime:GetConnectedOutput()
	if out and out:GetTool():GetAttrs().TOOLS_RegID == "BezierSpline" then
		found[#found + 1] = t
	end
end

local src = found[1]
if not src then
	print("[InvertRetime] No animated TimeStretcher in this comp.")
	return
end

if #found > 1 then
	local opts = {}
	for i, t in ipairs(found) do opts[i - 1] = t:GetAttrs().TOOLS_Name end
	local d = comp:AskUser("Invert Retime", {
		{ "Src", Name = "Read from", "Dropdown", Options = opts },
	})
	if not d then return end
	src = found[d.Src + 1]
end

-- sorted keys, so the monotonic check is meaningful
local keys = src.SourceTime:GetConnectedOutput():GetTool():GetKeyFrames()
local times = {}
for t in pairs(keys) do times[#times + 1] = t end
table.sort(times)

local inv, prev = {}, nil
for _, t in ipairs(times) do
	local k = keys[t]
	if prev and k[1] <= prev then
		print(string.format("[InvertRetime] Not monotonic at frame %g. Aborted.", t))
		return
	end
	prev = k[1]
	inv[k[1]] = { t, Flags = { Linear = true } }
end

comp:StartUndo("Invert Retime")
local spline = comp.BezierSpline({})
dst.Delay = spline
spline:SetKeyFrames(inv, true)
spline:SetKeyFrames(inv, true)   -- second pass makes the Linear flags stick
dst.Speed = 0
comp:EndUndo(true)

print(string.format("[InvertRetime] %s -> %s.Delay (%d keys)",
	src:GetAttrs().TOOLS_Name, dst:GetAttrs().TOOLS_Name, #times))