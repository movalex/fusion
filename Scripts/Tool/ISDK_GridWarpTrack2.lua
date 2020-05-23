--
--  Input Set Tool
--
--  Written by Kel Sheeran of ISDK Films
--
--  Copyright 2019
--
--  v1.0	17 Oct 2019		Prototype created
--  v1.1    18 Oct 2019     Fixed Bug on Creation of Animated Gridwarp, Added Source option.
--  V1.2    12 Nov 2019     Enhanced Tacking to Allow start points inside frame range rather than 0
--  v1.2.1  14 May 2020     Quickfix to use as comp script - by Alex Bogomolov
function get_tool()
    return comp.ActiveTool or comp:GetToolList(true)[1]
end
if not tool then
    tool = get_tool()
end
-- Globals
local newTracker = nil
local toolGW = tool

-- User Interface
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

-- Old Defaults
fPW = 0.02
fPH = 0.04
fSW = 0.035
fSH = 0.06

-- Current Defaults for Tracker Pattern and Search Sizes
fPW = 0.015
fPH = 0.025
fSW = 0.02
fSH = 0.04


-- Setup Window
tmpName = "Error"
if toolGW and tool.ID == "GridWarp" then
    tmpName = toolGW.Name
end

win = disp:AddWindow({
	ID = 'BCWin',
	WindowTitle = 'ISDK Gridwarp Tracker V1.2 Beta (c) 2019',
	Geometry = {800,200,360,260},
	Spacing = 5,
	ui:VGroup{
		ID = 'root',

		ui:HGroup{
			ui:Label{ID = 'var', Text = 'GridWarp', Weight = 0.2},
			ui:LineEdit{ID = 'varGridWarpIn',	Text = tmpName, Weight = 0.15},

		},

		ui:HGroup{
			ui.Label{ID = 'paramLbl', Text = 'Tracker Parameters:'}
		},
		
		ui:HGroup{
			ui:Label{ID = 'var', Text = 'Pattern Width', Weight = 0.15},
			ui:LineEdit{ ID = 'textPW', Text = tostring(fPW), Weight = 0.05},
			ui:Label{ID = 'var', Text = '  Height', Weight = 0.1},
			ui:LineEdit{ ID = 'textPH', Text = tostring(fPH), Weight = 0.05},
		},
		
		ui:HGroup{
			ui:Label{ID = 'var', Text = 'Search Width', Weight = 0.15},
			ui:LineEdit{ ID = 'textSW', Text = tostring(fSW), Weight = 0.05},
			ui:Label{ID = 'var', Text = '  Height', Weight = 0.1},
			ui:LineEdit{ ID = 'textSH', Text = tostring(fSH), Weight = 0.05},
		},
		
		ui:HGroup{		
			ui.Button{ID= 'btnTrackers', Text = '1. Make Tracker from GridWarp', Weight = 0.25}
		},
		
		ui:HGroup{
			ui:Label{ID = 'var', Text = 'Created Tracker', Weight = 0.2},
			ui:LineEdit{ID = 'varTracker',	Text = '', Weight = 0.2},
			ui.Button{ID = 'btnDoTrack', Text = '2. Run Tracking', Weight = 0.25}
		},
		
		ui:HGroup{
			ui:Label{ID = 'var', Text = 'GridWarp to Animate', Weight = 0.2},
			ui:ComboBox{ID = 'cmbDestType', Text = 'Combo Menu', Weight = 0.1},
		},
		
		ui:HGroup{
			ui:Button{ID = 'btnGridWarp', Text = '3. Create Animated GridWarp from Tracker',Weight = 0.4},

		},

		ui:HGroup{
			ui:Button{ID = 'btnClose', Text = 'Close',Weight = 0.4},
		},
	},
	
})



-- Deep Copy Utility function
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


--
-- Create Tracker From Gridwarp
--
function win.On.btnTrackers.Clicked(ev)

	if toolGW:GetID() ~= "GridWarp" then
		print 'ERROR: Please select a GridWarp node first.'
		return
	end

	gw = comp:CopySettings(toolGW)
	if (gw == nil) then
		print 'No Gridwarp Node'
		return
	end

	if comp:GetPrefs('Comp.Splines.TrackerPath') ~= 'PolyPath' then
		print 'Please set Preference for Splines/Tracker_Path to "Bezier Polyline"'
		return
	end
	
	-- Set Tracking Parmaters
	_sw = tonumber(itm.textSW.Text)
	_sh = tonumber(itm.textSH.Text)
	_pw = tonumber(itm.textPW.Text)
	_ph = tonumber(itm.textPH.Text)
	
	-- Validate Parameters
	if _sw <= 0 then _sw = fSW end
	if _sh <= 0 then _sh = fSH end
	if _pw <= 0 then _pw = fPW end
	if _ph <= 0 then _ph = fPH end

	_pt = comp.CurrentTime
	print('Using "'..toolGW.Name..'" destination points to Build Tracker from frame '.._pt)

	_pts = gw.Tools[toolGW.Name].Inputs.SrcGridChange.Value.Points
	n = (toolGW.DstXGridSize[comp.CurrentTime] + 1) * (toolGW.DstYGridSize[comp.CurrentTime] + 1)
	trkr = comp.Tracker()
	trkr:SetAttrs({TOOLS_Name = 'WarpTracker', TOOLNT_EnabledRegion_Start = _pt })
	tr = comp:CopySettings(trkr)
	trkr:Delete()

	-- Setup Trackers
	for i = 1, n do
		_trkName = 'Tracker '..i
		tr.Tools[trkr.Name].Trackers[i] = { PatternTime = _pt, PatternX = _pts[i].X+0.5, PatternY = _pts[i].Y+0.5 }
		--tr.Tools[trkr.Name].Trackers[i] = { PatternTime = _pt, PatternX = 0, PatternY = 0 }
		tr.Tools[trkr.Name].Inputs['PatternCenter'..i] = { __ctor = 'Input', __flags = 256, Value = { _pts[i].X+0.5, _pts[i].Y+0.5 } } 
		tr.Tools[trkr.Name].Inputs['SearchWidth'..i] = { __ctor = 'Input', __flags = 256, Value = _sw } 
		tr.Tools[trkr.Name].Inputs['SearchHeight'..i] = { __ctor = 'Input', __flags = 256,Value=_sh }
		tr.Tools[trkr.Name].Inputs['PatternWidth'..i] = { __ctor = 'Input', __flags = 256,Value=_pw }
		tr.Tools[trkr.Name].Inputs['PatternHeight'..i] = { __ctor = 'Input', __flags = 256,Value=_ph } 
		
	end

	--print(tr)
	-- Create Tracker
	comp:SetActiveTool(nil)
	
	if not comp:Paste(tr) then
		print 'Error creating Tracker'
		return
	end
	
	-- Configure the new Tracker
	newTracker = comp.ActiveTool
	
	itm.varTracker.Text = newTracker.Name
	newTracker.AdaptiveMode = 2
	newTracker.ShowPatternNamesInPreview = false
	print('"'..newTracker.Name..'" created, with '..n ..' trackers')
	
	-- Attach to Gridwarp parent if exists
	lnk = toolGW:FindMainInput(1)
	if lnk then
		s = lnk:GetConnectedOutput():GetTool()
		newTracker.Input:ConnectTo(s.Output)
	end 
	
	-- Set the Tracker to View
	comp.CurrentFrame:ViewOn(newTracker,1)
end


--
-- Create the Animated GridWarp
--
function win.On.btnGridWarp.Clicked(ev)
	toolTR = comp:FindTool(itm.varTracker.Text)
	
	if toolTR == nil then
		print 'ERROR: Please use a valid Tracker node.'
		return
	end
	
	if toolTR:GetID() ~= "Tracker" then
		print 'ERROR: Node is not a Tracker node.'
		return
	end

	-- Get the tracker settings
	print ('Using Tracker "'..toolTR.Name..'" and GridWarp "'..toolGW.Name..'" animating '..itm.cmbDestType.CurrentText)
	
	useDest = (itm.cmbDestType.CurrentText == 'Destination')
	
	-- Make a Copy of the GridWarp
	comp:Lock()
	comp:Copy(toolGW)
	comp:Paste()
	tempGW = comp:ActiveTool()
	if useDest then
		tempGW:SetAttrs({TOOLS_Name = 'AnimDstWarp'})
	else
		tempGW:SetAttrs({TOOLS_Name = 'AnimSrcWarp'})
	end
	
	-- Set Animation
	if useDest then
		tempGW.DstGridChange = nil
		tempGW.DstGridChange = comp:BezierSpline({})
		targetData = 'DstGridChange'
	else
		tempGW.SrcGridChange = nil
		tempGW.SrcGridChange = comp:BezierSpline({})
		targetData = 'SrcGridChange'
	end

	-- Make Copy of Settings
	gw = comp:CopySettings(tempGW)

	
	tr = comp:CopySettings(toolTR) 
	--dump(gw)
	kf = gw.Tools[tempGW.Name..targetData].KeyFrames
	n = (tempGW.DstXGridSize[comp.CurrentTime] + 1) * (tempGW.DstYGridSize[comp.CurrentTime] + 1)
	print (n .. ' trackers being used')

	tempkf = kf[comp.CurrentTime]
	--dump(tempkf)
	if tempkf == nil then
		print ('No Keyframe found at ' .. comp.CurrentTime)
		tempGW:Delete()
        comp:Unlock()
		return
	end
	
	if tr.Tools[toolTR.Name..'Tracker1Path'] == nil then
		print("No tracking data to export")
		tempGW:Delete()
        comp:Unlock()
		return		
	end
    comp:Unlock()

	i=0	
	while true do
        	
		tmpText = tr.Tools[toolTR.Name..'Tracker'..(i+1)..'Path'].Inputs.Displacement.SourceOp
        print('Processing tracker: '.. i)
		
		k=0
		while tr.Tools[tmpText].KeyFrames[k] == nil do k = k + 1 end		
		
		gw.Tools[tempGW.Name..targetData].KeyFrames[i+k] = deepcopy(tempkf)
		gw.Tools[tempGW.Name..targetData].KeyFrames[i+k][1] = i
        -- print (gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i][1])
		

		
		for j = 1, n do

			_pts = tr.Tools[toolTR.Name..'Tracker'..j..'Path'].Inputs.PolyLine.Value.Points[i+1]
			if _pts == nil then 
				gw.Tools[tempGW.Name..targetData].KeyFrames[i+k] = nil
				break
			end

			--print ('Time ' .. i .. '    Tracker '..j..'   '.._pts.X..','.._pts.Y )
			gw.Tools[tempGW.Name..targetData].KeyFrames[i+k].Value.Points[j] = { LinearX = true, LinearY = true, X = _pts.X, Y = _pts.Y, 
					L_CX=0, L_CY=0, R_CX=0, R_CY=0, T_CX=0, T_CY=0,B_CX=0, B_CY=0 }
			
		end

		--dump (pts)
		if _pts == nil then break end
		i = i + 1

	end

	tempGW:Delete()
	
	--print(tr)
	print 'Creating new GridWarp'
	comp:SetActiveTool(nil)
	if not comp:Paste(gw) then
		print 'ERROR: Unable to create new Tracked Warp'
		
		return
	end
	
	-- Config new Grid Warp
	newGW = comp.ActiveTool()
	newGW.Input = nil
	if useDest then
		newGW.CopyDestToSrc[0] = 1
	else
		newGW.CopySrcToDest[0] = 1
	end
	
	print ('"'..newGW.Name..'" created')

    comp:Unlock()
end


--
-- Run Tracker
--
function win.On.btnDoTrack.Clicked(ev)

	if not newTracker then
		newTracker = comp:FindTool(itm.varTracker.Text)
	end
	
	if newTracker == nil then
		print 'ERROR: Please use a valid Tracker node.'
		return
	end
	
	if newTracker:GetID() ~= "Tracker" then
		print 'ERROR: Node is not a Tracker node.'
		return
	end
	
	if newTracker then
		print ('Running Tracking for "'..newTracker.Name..'" from frame ' .. comp.CurrentTime)		
		newTracker.TrackForward = 1
	else
		print "No tracker has been set"
	end
end


-- Window Close
function win.On.btnClose.Clicked(ev)
	disp:ExitLoop()
end


-- Window Close
function win.On.BCWin.Close(ev)
	disp:ExitLoop()
end



--
-- Main Loop
--

itm = win:GetItems()

local tr_tool = get_tool()
if itm.varTracker.Text == "" and tr_tool.ID == "Tracker" then
    itm.varTracker.Text = tr_tool.Name
end	
itm.cmbDestType:AddItem('Destination')
itm.cmbDestType:AddItem('Source')

	
win:Show()
disp:RunLoop()
win:Hide()


