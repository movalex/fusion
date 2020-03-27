--[[
                      se_EasyNow!
					  
© 2018 by Eric 'SirEdric' Westphal (eric@siredric.de)
Easing Equations © 2001 Robert Penner (see disclaimer below)
Thanks to Andrew Hazelden for his amazing GUI example Scripts on the best Fusion Forum ever:
https://www.steakunderwater.com/wesuckless/viewtopic.php?f=6&t=1411

Interactively apply a wealth of easing functions to BMD Fusion's Animation Splines.
Perfect for all sorts of Motion Graphics
See [no youtube link yet] for a short demonstration

If you like this script, why not buy me a [coffee|bike|car|boat|swiss chalet] by donating on https://www.paypal.me/siredric

--]]--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Easing CheatSheet:
https://easings.net/de

--]]--

----------------------------------------------------------- <Robert Penner's Easing Equations>

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)


local pow = math.pow
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin
local pi = math.pi

function linear(t, b, c, d)
  return c * t / d + b
end

function inQuad(t, b, c, d)
  t = t / d
  return c * pow(t, 2) + b
end

function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

function inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 2) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end

function outInQuad(t, b, c, d)
  if t < d / 2 then
    return outQuad (t * 2, b, c / 2, d)
  else
    return inQuad((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inCubic (t, b, c, d)
  t = t / d
  return c * pow(t, 3) + b
end

function outCubic(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 3) + 1) + b
end

function inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t * t * t + b
  else
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
end

function outInCubic(t, b, c, d)
  if t < d / 2 then
    return outCubic(t * 2, b, c / 2, d)
  else
    return inCubic((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inQuart(t, b, c, d)
  t = t / d
  return c * pow(t, 4) + b
end

function outQuart(t, b, c, d)
  t = t / d - 1
  return -c * (pow(t, 4) - 1) + b
end

function inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 4) + b
  else
    t = t - 2
    return -c / 2 * (pow(t, 4) - 2) + b
  end
end

function outInQuart(t, b, c, d)
  if t < d / 2 then
    return outQuart(t * 2, b, c / 2, d)
  else
    return inQuart((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inQuint(t, b, c, d)
  t = t / d
  return c * pow(t, 5) + b
end

function outQuint(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 5) + 1) + b
end

function inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (pow(t, 5) + 2) + b
  end
end

function outInQuint(t, b, c, d)
  if t < d / 2 then
    return outQuint(t * 2, b, c / 2, d)
  else
    return inQuint((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inSine(t, b, c, d)
  return -c * cos(t / d * (pi / 2)) + c + b
end

function outSine(t, b, c, d)
  return c * sin(t / d * (pi / 2)) + b
end

function inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

function outInSine(t, b, c, d)
  if t < d / 2 then
    return outSine(t * 2, b, c / 2, d)
  else
    return inSine((t * 2) -d, b + c / 2, c / 2, d)
  end
end

function inExpo(t, b, c, d)
  if t == 0 then
    return b
  else
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
  end
end

function outExpo(t, b, c, d)
  if t == d then
    return b + c
  else
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
  end
end

function inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  else
    t = t - 1
    return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
  end
end

function outInExpo(t, b, c, d)
  if t < d / 2 then
    return outExpo(t * 2, b, c / 2, d)
  else
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inCirc(t, b, c, d)
  t = t / d
  return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

function outCirc(t, b, c, d)
  t = t / d - 1
  return(c * sqrt(1 - pow(t, 2)) + b)
end

function inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return -c / 2 * (sqrt(1 - t * t) - 1) + b
  else
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
end

function outInCirc(t, b, c, d)
  if t < d / 2 then
    return outCirc(t * 2, b, c / 2, d)
  else
    return inCirc((t * 2) - d, b + c / 2, c / 2, d)
  end
end

function inElastic(t, b, c, d, a, p)
  if t == 0 then return b end
  t = t / d
  if t == 1  then return b + c end
  if not p then p = d * 0.3 end
  local s
  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end
  t = t - 1
  return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
function outElastic(t, b, c, d, a, p)
  if t == 0 then return b end
  t = t / d
  if t == 1 then return b + c end
  if not p then p = d * 0.3 end
  local s
  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end
  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
function inOutElastic(t, b, c, d, a, p)
  if t == 0 then return b end
  t = t / d * 2
  if t == 2 then return b + c end
  if not p then p = d * (0.3 * 1.5) end
  if not a then a = 0 end
  local s
  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c / a)
  end
  if t < 1 then
    t = t - 1
    return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  else
    t = t - 1
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
  end
end

-- a: amplitud
-- p: period
function outInElastic(t, b, c, d, a, p)
  if t < d / 2 then
    return outElastic(t * 2, b, c / 2, d, a, p)
  else
    return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
  end
end

function inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

function inOutBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  s = s * 1.525
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * ((s + 1) * t - s)) + b
  else
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
  end
end

function outInBack(t, b, c, d, s)
  if t < d / 2 then
    return outBack(t * 2, b, c / 2, d, s)
  else
    return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
  end
end

function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

function inOutBounce(t, b, c, d)
  if t < d / 2 then
    return inBounce(t * 2, 0, c, d) * 0.5 + b
  else
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
  end
end

function outInBounce(t, b, c, d)
  if t < d / 2 then
    return outBounce(t * 2, b, c / 2, d)
  else
    return inBounce((t * 2) - d, b + c / 2, c / 2, d)
  end
end

----------------------------------------------------------- </Robert Penner's Easing Equations> ---------------------------------------------------


---------------------------------------------------------------- <SirEdric's se_EasyNow!> ---------------------------------------------------------

------------------------------------------------------------------- [ GENERAL DEFS ] -----------------------------
_VERSION = "0.91"
unbakeable = { Image = true, Mask = true, Particles = true, DataType3D = true, MtlGraph3D = true, Center = true} -- ["XY Path"] = true .. XYPath = true
mods = { Point = true, Text = true, Center = true, XYPath = true } 
--ctrls = { Center = true, } 
allowedTypes = { BezierSpline = true, } -- currently the only splinetype we can use :SetKeyFrames() with....
ezFuncs = {"linear", "inQuad", "outQuad", "inOutQuad", "outInQuad", "inCubic", "outCubic", "inOutCubic", "outInCubic", "inQuart", "outQuart", "inOutQuart", "outInQuart", "inQuint", "outQuint", "inOutQuint", "outInQuint", "inSine", "outSine", "inOutSine", "outInSine", "inExpo", "outExpo", "inOutExpo", "outInExpo", "inCirc", "outCirc", "inOutCirc", "outInCirc", "inElastic", "outElastic", "inOutElastic", "outInElastic", "inBack", "outBack", "inOutBack", "outInBack", "outBounce", "inBounce", "inOutBounce", "outInBounce" }

cntInp = 0
myItems = {}
myTypes = {}
myAnims = {}
typeFilter = "All"
dispToolName = "none"
sldDiv = 10 -- dividing the value of the Power and Amplitude Sliders
minInterval = 2 --minimum time interval between two keyframes 
bakeStep = 1 -- interval between keyframes when baking the equation
-- amp = nil
-- pwr = nil
ezFunc = "linear"

---------------------------------------------------------------------------------[ GUI ] -------------------------------------
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 375,450

win = disp:AddWindow({
  ID = 'wEasyNow',
  WindowTitle = 'se_EasyNow v' .. _VERSION,
  Geometry = {100, 100, width, height},
  Spacing = 0,
  
  ui:VGroup{
    ID = 'root',
	ui:HGroup{
		Weight = 0.001,
			ui:Label{ID = 'Label7', Text = 'Easing Method', Weight = 0.01},
			ui:ComboBox{ID = 'ezMethod', Text = 'Combo Menu'},

	},
	ui:HGroup{
		Weight = 0,
			ui:CheckBox{ID = 'doLive', Text = 'Live Update', Checked = true, Weight = 0.01},
			ui:CheckBox{ID = 'skipStatic', Text = 'Skip Static KFs', Checked = true, Weight = 0.01},
			ui:CheckBox{ID = 'verbose', Text = 'Verbose', Checked = false, Weight = 0.01},
	},
	--ui:VGap(3),
	ui:HGroup{
		Weight = 0.5,
		ui:VGroup{
			--ui:Label{ID = 'lblTool', Text = 'Select the Controls to add an Expression to.', Alignment = {AlignHCenter = true, AlignTop = true},},
			ui:Label{ID = 'lblTool', Text = 'Selected Tool: ' .. dispToolName, Weight = 0.01},
			ui:Tree{ID = 'Tree', SortingEnabled=true, Events = {ItemDoubleClicked=true, ItemClicked=true},},
			ui:HGroup{Weight = 0.01,
				ui:Button{ID = 'butAll', Weight = 0.01, Text = 'All', Enabled = true},
				ui:Button{ID = 'butNone', Weight = 0.01, Text = 'None', Enabled = true},
				ui:Button{ID = 'butInvert', Weight = 0.01, Text = 'Invert', Enabled = true},
			},
		},
	},
		
	--ui:VGap(3),
	ui:VGroup{
		Weight = 0,
			ui:Label{ID = 'lblAmpT', Text = 'Amplitude (on special equations only)', Weight = 0.1,},
			ui:HGroup{
				ui:Slider{ID = 'sldAmp', Weight = 0.8,},
				ui:Label{ID = 'lblAmp', Text = 'Auto', Weight = 0.1,},
			},
			
			ui:Label{ID = 'lblPowerT', Text = 'Power (on special equations only)', Weight = 0.1,},
			ui:HGroup{
				ui:Slider{ID = 'sldPower', Weight = 0.8,},
				ui:Label{ID = 'lblPower', Text = 'Auto', Weight = 0.1,},
			},
			ui:Label{ID = 'lblStepsT', Text = 'Bake Stepping', Weight = 0.1,},
			ui:HGroup{
				ui:Slider{ID = 'sldSteps', Weight = 0.8,},
				ui:Label{ID = 'lblSteps', Text = '1', Weight = 0.1,},
			},
		},
	ui:HGroup{
		Weight = 0,
			ui:Button{ID = 'butOkay', Text = 'Apply', Enabled = true},
			ui:Button{ID = 'butUndo', Text = 'Reset', Enabled = true},
			ui:Button{ID = 'butRefresh', Text = 'Refresh', Enabled = true},
			ui:Button{ID = 'butCncl', Text = 'Close', Enabled = true},
		},
  },
})



-- Add your GUI element based event functions here:
itm = win:GetItems()

-- assign control values

itm.sldPower.Value = 0
itm.sldPower.Minimum = 0
itm.sldPower.Maximum = 100

itm.sldAmp.Value = 0
itm.sldAmp.Minimum = 0
itm.sldAmp.Maximum = 100

itm.sldSteps.Value = bakeStep
itm.sldSteps.Minimum = 1
itm.sldSteps.Maximum = 10


-- fill dropdown
for _, op in pairs(ezFuncs) do
	itm.ezMethod:AddItem(op)
end

-- The window was closed
function win.On.wEasyNow.Close(ev)
    disp:ExitLoop()
end

function win.On.butCncl.Clicked(ev)
	disp:ExitLoop()
	do return end
end

function win.On.Tree.ItemClicked(ev)
	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function win.On.butUndo.Clicked(ev)
	undoSplines()
	itm.sldPower.Value = 0
	itm.sldAmp.Value = 0
end

function win.On.butRefresh.Clicked(ev)
	init()
end

function win.On.butInvert.Clicked(ev)
	dPrint("Items: ", myItems)
	for _, item in pairs(myItems) do
		if item.CheckState[0] == "Checked" then
			item.CheckState[0] = "Unchecked"
		else
			if item.Text[1] == "anim" or itm.skipStatic.Checked == false then
				item.CheckState[0] = "Checked"
			end
		end
	end
	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function win.On.butAll.Clicked(ev)
	for _, item in pairs(myItems) do
		if item.Text[1] == "anim" or itm.skipStatic.Checked == false then
			item.CheckState[0] = "Checked"
		end
	end
	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function win.On.butNone.Clicked(ev)
	for _, item in pairs(myItems) do
		item.CheckState[0] = "Unchecked"
	end
	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function win.On.butOkay.Clicked(ev)
	easeSections2()
end

function win.On.ezMethod.CurrentIndexChanged(ev)
	sIdx = itm.ezMethod.CurrentIndex
	dPrint(sIdx)
	ezFunc = ezFuncs[sIdx + 1]
	dPrint(ezFunc)
	-- change the splines on the fly!
	if itm.doLive.Checked == true then
		easeSections2()
	end
end


function win.On.sldPower.ValueChanged(ev)
	if ev.Value == 0 then
		itm.lblPower.Text = 'Auto'
		pwr = nil
	else
		itm.lblPower.Text = tostring(ev.Value/sldDiv)
		pwr = ev.Value/sldDiv
	end
	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function win.On.sldAmp.ValueChanged(ev)
	if ev.Value == 0 then
		itm.lblAmp.Text = 'Auto'
		amp = nil
	else
		itm.lblAmp.Text = tostring(ev.Value/sldDiv)
		amp = ev.Value/sldDiv
	end
	if itm.doLive.Checked == true then
		easeSections2()
	end
end


function win.On.sldSteps.ValueChanged(ev)
	itm.lblSteps.Text = tostring(ev.Value)
	bakeStep = ev.Value

	if itm.doLive.Checked == true then
		easeSections2()
	end
end

function buildTree()
	-- Add a header row
	hdr = itm.Tree:NewItem()
	hdr.Text[0] = 'Control ID / Ranges'
	hdr.Text[1] = 'Type'
	itm.Tree:SetHeaderItem(hdr)

	-- Number of columns in the Tree list
	itm.Tree.ColumnCount = 2

	-- Resize the Columns
	itm.Tree.ColumnWidth[0] = 250
	itm.Tree.ColumnWidth[1] = 50
end



------------------------------------------------------------------- [ GENERAL FUNCTIONS ] -----------------------------

function dPrint(dMsg, dTbl)
	if itm.verbose.Checked == true then
		dPrint(dMsg)
		if dTbl then
			dump(dTbl)
		end
	print("----------")
	-- dMsg = nil
	-- dTbl = nil
	end
end

function tableSort(sortMe)
	theOrder = {}
	for k, v in pairs(sortMe) do
		table.insert(theOrder, tonumber(k))
	end
	table.sort(theOrder)
	--dump(theOrder)
	return theOrder
end

function tableShallowCopy(t)
	-- just doing table2 = table1 won't work, since that only creates a *reference* to the original table!
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function findSections()
	-- each section is defined by two consecutive keyframes
	keySections = {}
	
	for k, t in pairs(theOrder) do
		if theOrder[k+1] then --is there any more keyframe left?
			sectionType = "anim"

			-- mark static keys
			dPrint("Section [" .. t .. "]")
			dPrint("keys on " , kfs)
			print("dataType: " .. type(kfs[t]))
			if type(kfs[t]) == "table" then -- there might be tables without actual keyframe subtables....
				if kfs[t][1] == kfs[theOrder[k+1]][1] then
					dPrint("Section [" .. k .. "]: Consecutive Keyframes have identical values.")
					sectionType = "static"
				elseif theOrder[k+1] - t < minInterval then
					sectionType = "step"
		-- TODO: Group Steps like 1[..]20
				end
			-- both time and value go directly into this table!
				keySections[k] = {t, theOrder[k+1], kfs[t][1], kfs[theOrder[k+1]][1], sectionType}
			end
		end
	end
	-- print("keySections")
	-- dump(keySections)
end


function easeSections2()
	for ctrlName, Ops in pairs(allSplines) do
		curSpline = Ops[1]
		keySections = Ops[2]
		newKeys = {}
		for s, section in pairs(keySections) do
			itmCheck = ctrlName .. s
				startVal = section[3]
				endVal = section[4]
				change = endVal - startVal
				
				startTime = section[1]
				endTime = section[2]
				duration = endTime - startTime
				
				newKeys[startTime] = {startVal}
				dPrint("Start:" .. startVal)
				
				if myItems[itmCheck] then -- hidden step items may be nil. We still need to keep them though to not overwrite them.
					if myItems[ctrlName].CheckState[0] == "Checked"  and myItems[itmCheck].CheckState[0] == "Checked" then
						for curVal = 1, duration - 1, bakeStep do
							--newVal = outInBounce(curVal, startVal, change, duration)
							--newVal = inOutBack(curVal, startVal, change, duration)
							newVal = getfenv()[ezFunc](curVal, startVal, change, duration, amp, pwr)
							--dPrint(newVal)
							newKeys[startTime + curVal] = {newVal}
						end
					end
				end
				dPrint("End:" .. endVal)
				newKeys[endTime] = {endVal}
				dPrint("NewKeys: ", newKeys)
			--end
		end
		dump(curSpline)
		curSpline:SetKeyFrames(newKeys, true) -- 'true' replaces the entire animation spline, rather than adding keyframes
-- TODO: Add an Option to make curSpline into CubicSpline(for auto smoothing?)
		-- cuSpline = comp.CubicSpline()
		-- cuSpline:SetKeyFrames(newKeys, true)
		-- activeTool[ctrlName] = cuSpline
	end
end

function UpdateTree()
	-- Clean out the previous entries in the Tree view
	itm.Tree:Clear()
	myItems = {}
	itm.lblTool.Text = 'Selected Tool: ' .. dispToolName

-- TODO: Get rid of curSplines, use allSplines instead
    --for i, inp in pairs(curSplines) do
    for i, inp in pairs(allSplines) do
		--if inp[2] == typeFilter or typeFilter == "All" then
			itRow = itm.Tree:NewItem(); 
			
			itRow.Text[0] = i
			itRow.Text[1] = inp[1]
			itRow.CheckState[0] = "Checked"
			itm.Tree:AddTopLevelItem(itRow)
			myItems[i] = itRow
			--dump(curItem)
		--end
    end  
end


function updateItem()

	sectionItems = {}
	for name, stuff in pairs(allSplines) do
		curMaster = myItems[name]
		dPrint(curMaster)
		
		for count, section in pairs(stuff[2]) do
			dPrint(count)
			-- hide steps here?
			if section[5] ~= "step" then
				sectionDur = section[1] .. " - " .. section[2]
				curSectionItem = itm.Tree:NewItem()
				curSectionItem.Text[0] = sectionDur
				curSectionItem.Text[1] = section[5]

				if section[5] == "anim" then
					curSectionItem.CheckState[0] = "Checked"
				else
					curSectionItem.CheckState[0] = "Unchecked"
				end

				curMaster:AddChild(curSectionItem)
				curMaster.Expanded = true
				sectionItems[name .. count] = curSectionItem
				myItems[name .. count] = curSectionItem
			end
		end
	end
end

function oneUp(traitor)
	--local parent = traitor:GetConnectedOutput():GetTool()
	--local parentName = parent:GetAttrs().TOOLS_Name
	activeTool = traitor:GetConnectedOutput():GetTool()
	curToolName = activeTool:GetAttrs().TOOLS_Name
	if not dispToolName:find(curToolName) then
		dispToolName = dispToolName .. " - " .. curToolName
	end
	
	getSplines2()
end

function getSplines2()
	curSplines = {}
	allSplines = {}
	
	for key,inp in pairs(activeTool:GetInputList()) do
		if inp:GetConnectedOutput() then
			inpType = inp:GetAttrs().INPS_DataType
			controlID = inp:GetAttrs().INPS_ID  --Transform3DOp.Translate.X
			dPrint("INPS_DataType: " .. inpType)
			dPrint("controlID [" .. controlID.."]" )
			
			if mods[inpType] then oneUp(inp) end

			if not unbakeable[inp:GetAttrs().INPS_DataType] then

				spline = inp:GetConnectedOutput():GetTool()
				splineType = spline:GetAttrs().TOOLS_RegID
				
				--if splineType == "BezierSpline" then
				if allowedTypes[splineType] then
					-- curSplines[inp.Name] = spline
					curSplines[controlID] = spline
					
					kfs = spline:GetKeyFrames(true)
					kfsBackup[controlID] = tableShallowCopy(kfs)
					tableSort(kfs)
					--TODO: Copy entire Spline object for later restore?
					--dPrint("kfs", kfs)
					
					findSections()

					allSplines[controlID] = {spline, keySections}
				end

			end
		end
	end
	--dump(curSplines)
end

function undoSplines()
	for ctrl, keys in pairs(kfsBackup) do
		dPrint("Undo:", activeTool[ctrl])
		spline = activeTool[ctrl]:GetConnectedOutput():GetTool()
		spline:SetKeyFrames(keys, true)
	end
end


function init()
	kfsBackup = {}
	
	activeTool = comp.ActiveTool
	--activeTool = comp:FindTool("XYPath2")
	
	if activeTool then
		curToolName = activeTool:GetAttrs().TOOLS_Name
		dispToolName = curToolName
		getSplines2()
	end

	buildTree()

	if activeTool then
		UpdateTree()
		updateItem()
	end
end

--------------------------------------------------- Off we go!
print(collectgarbage())
init()

win:Show()
disp:RunLoop()

win:Hide()
collectgarbage()

print("If you like this script, why not buy me a [coffee|bike|car|boat|swiss chalet] by donating on https://www.paypal.me/siredric")
---------------------------------------------------------------- </SirEdric's se_EasyNow!> ---------------------------------------------------------

