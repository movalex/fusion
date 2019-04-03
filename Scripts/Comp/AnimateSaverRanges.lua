--[[
-------------------------------------------------------------------------------------------------------------------------
SaverRanges

this script animates the range in which the saver is active

it builds a list of all savers in the comp and let the user deside which should be active and in which range
by default all savers are active (besides if the are in passthrough or not) and the renderange is the comp renderrange

v0.2.2 Fusion9 compatibility 3/4/2019
v0.2.1 01.09.2008
	fixed bug for creating a keyframe at current time with blend = 0
v0.2 inital release 27.03.2008
	added setting of new renderrange in conjunction with ranges of savers (min renderstart becomes renderrange start and max renderend becomes renderrange end)
	added check if start < end
v0.1 inital release 26.03.2008

-------------------------------------------------------------------------------------------------------------------------
--]]

fusion = Fusion()

composition = fusion:GetCurrentComp()

local attrs = composition:GetAttrs()
local prefs = fusion:GetPrefs()

local RenderStart = attrs.COMPN_RenderStartTime
local RenderEnd = attrs.COMPN_RenderEndTime
local GlobalStart = attrs.COMPN_GlobalStart

local SaverTable = bmd.GetSavers(composition)

local dialog = {}
local dialogcounter = 1


composition:StartUndo("SaverRangesScript")

for i, v in ipairs(SaverTable) do
	dialog[dialogcounter] = {"process"..i, Name= "Process: "..v:GetAttrs().TOOLS_Name, "Checkbox", Default=1, NumAcross=2}
	dialog[dialogcounter+1] = {"renderrange"..i, Name="RenderRange", "Position", Default = {RenderStart, RenderEnd} }
	dialogcounter = dialogcounter + 2
end
dialog[dialogcounter+1] = {"",  "Text", Lines = 0, ReadOnly=true}
dialog[dialogcounter+2] = {"newrange", Name= "Set new renderrange?", "Checkbox", Default=1, NumAcross=2}

ask = composition:AskUser("Savers", dialog)

if ask == nil then print("cancelled") return end

local RenderEndNew = ask.renderrange1[2]
local RenderStartNew = ask.renderrange1[1]


for i, v in ipairs(SaverTable) do
	local processVar = "process"..i
	local renderrangeVar = "renderrange"..i
	local start = ask[renderrangeVar][1]
	local ende = ask[renderrangeVar][2]
	if start > ende then
		a = start
		start = ende
		ende = a
	end
	if ask[processVar] == 0 then
		v:SetAttrs({TOOLB_PassThrough = true})
	end
	if ask[processVar] == 1 then
		v:SetAttrs({TOOLB_PassThrough = false})
		v.ProcessWhenBlendIs00 = 1
		v:AddModifier('Blend', 'BezierSpline')
		if ((attrs.COMPN_CurrentTime > start) and (attrs.COMPN_CurrentTime < ende)) then
			v.Blend[attrs.COMPN_CurrentTime] = 1
		elseif attrs.COMPN_CurrentTime > ende then
			v.Blend[attrs.COMPN_CurrentTime] = 0
		elseif attrs.COMPN_CurrentTime < start then
			v.Blend[attrs.COMPN_CurrentTime] = 0
		end
		v.Blend[start - 1] = 0
		v.Blend[start] = 1
		v.Blend[ende] = 1
		v.Blend[ende+1] = 0
		if ende > RenderEndNew then RenderEndNew = ende end
		if start < RenderStartNew then RenderStartNew = start end
	end
end

if ask.newrange == 1 then
	composition:SetAttrs({COMPN_RenderStart = RenderStartNew})
	composition:SetAttrs({COMPN_RenderEnd = RenderEndNew})
end

composition:EndUndo(true)
