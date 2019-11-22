--
--  Input Set Tool
--
--  Written by Kel Sheeran of ISDK Films
--
--  Copyright 2019
--
--  v1.0	117 Oct 2019		Prototype created


-- Globals
local newTracker = nil
local toolGW = tool

-- User Interface
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

-- Defaults
fPW = 0.02
fPH = 0.04
fSW = 0.035
fSH = 0.06




-- Setup Window
win = disp:AddWindow({
	ID = 'BCWin',
	WindowTitle = 'ISDK Gridwarp Tracker V1.0 Beta (c) 2019',
	Geometry = {800,200,350,240},
	Spacing = 5,
	ui:VGroup{
		ID = 'root',

		ui:HGroup{
			ui:Label{ID = 'var', Text = 'GridWarp', Weight = 0.2},
			ui:LineEdit{ID = 'varGridWarpIn',	Text = toolGW.Name, Weight = 0.15},

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
		print ("ERROR: Please select a Tracker node first.")
		return
	end

	gw = composition:CopySettings(toolGW)
	if (gw == nil) then
		print("No Gridwarp Node")
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

	
	print('Using "'..toolGW.Name..'" destination points to Build Tracker')

	_pts = gw.Tools[toolGW.Name].Inputs.SrcGridChange.Value.Points
	n = (toolGW.DstXGridSize[composition.CurrentTime] + 1) * (toolGW.DstYGridSize[composition.CurrentTime] + 1)
	trkr = comp.Tracker()
	tr = composition:CopySettings(trkr)
	trkr:Delete()

	-- Setup Trackers
	for i = 1, n do
		_pt = 0
		_trkName = 'Tracker '..i
		tr.Tools[trkr.Name].Trackers[i] = { PatternTime = _pt, PatternX = _pts[i].X+0.5, PatternY = _pts[i].Y+0.5 }
		tr.Tools[trkr.Name].Inputs['PatternCenter'..i] = { __ctor = 'Input', __flags = 256, Value = { _pts[i].X+0.5, _pts[i].Y+0.5 } } 
		tr.Tools[trkr.Name].Inputs['SearchWidth'..i] = { __ctor = 'Input', __flags = 256, Value = _sw } 
		tr.Tools[trkr.Name].Inputs['SearchHeight'..i] = { __ctor = 'Input', __flags = 256,Value=_sh }
		tr.Tools[trkr.Name].Inputs['PatternWidth'..i] = { __ctor = 'Input', __flags = 256,Value=_pw }
		tr.Tools[trkr.Name].Inputs['PatternHeight'..i] = { __ctor = 'Input', __flags = 256,Value=_ph } 
		
	end

	--print(tr)
	-- Create Tracker
	composition:SetActiveTool(nil)
	if not comp:Paste(tr) then
		print 'Error creating Tracker'
		return
	end
	
	-- Configure the new Tracker
	newTracker = comp.ActiveTool
	newTracker:SetAttrs({TOOLS_Name = 'WarpTracker'})
	itm.varTracker.Text = newTracker.Name
	newTracker.AdaptiveMode = 2
	print('"'..trkr.Name..'" created, with '..n ..' trackers')
	
	-- Attach to Gridwarp parent if exists
	lnk = toolGW:FindMainInput(1)
	if lnk then
		s = lnk:GetConnectedOutput():GetTool()
		newTracker.Input:ConnectTo(s.Output)
	end 
	
end


--
-- Create the Animated GridWarp
--
function win.On.btnGridWarp.Clicked(ev)
	
	toolTR = composition:FindTool(itm.varTracker.Text)
	
	if toolTR == nil then
		print 'ERROR: Please use a valid Tracker node.'
		return
	end
	
	if toolTR:GetID() ~= "Tracker" then
		print 'ERROR: Node is not a Tracker node.'
		return
	end

	-- Get the tracker settings
	print ('Using Tracker "'..toolTR.Name..'" and GridWarp "'..toolGW.Name..'"')
	
	-- Set Animation
	toolGW.DstGridChange = nil
	toolGW.DstGridChange = composition:BezierSpline({})

	tr = composition:CopySettings(toolTR) 
	
	-- Make Copy
	gw = composition:CopySettings(toolGW)
	--dump(gw)
	kf = gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames
	n = (toolGW.DstXGridSize[composition.CurrentTime] + 1) * (toolGW.DstYGridSize[composition.CurrentTime] + 1)
	print (n .. ' trackers being used')

	tempkf = kf[composition.CurrentTime]
	--dump(tempkf)

	i=0
	while true do
		--print ('Trying frame '..i)

		gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i] = deepcopy(tempkf)
		gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i][1] = i
		--print (gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i][1])
		for j = 1, n do

			_pts = tr.Tools[toolTR.Name..'Tracker'..j..'Path'].Inputs.PolyLine.Value.Points[i+1]
			if _pts == nil then 
				gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i] = nil
				break
			end

			--print ('Time ' .. i .. '    Tracker '..j..'   '.._pts.X..','.._pts.Y )
			
			gw.Tools[toolGW.Name..'DstGridChange'].KeyFrames[i].Value.Points[j] = { LinearX = true, LinearY = true, X = _pts.X, Y = _pts.Y, 
					L_CX=0, L_CY=0, R_CX=0, R_CY=0, T_CX=0, T_CY=0,B_CX=0, B_CY=0 }
			
		end

		--dump (pts)
		if _pts == nil then break end
		i = i + 1

	end

	--print(tr)
	print 'Creating new GridWarp'
	composition:SetActiveTool(nil)
	if not comp:Paste(gw) then
		print 'ERROR: Unable to create new Tracked Warp'
		return
	end
	
	-- Config new Grid Warp
	composition.CurrentTime = 0
	newGW = composition.ActiveTool()
	newGW.Input = nil
	newGW.CopyDestToSrc[0] = 1
	newGW:SetAttrs({TOOLS_Name = 'TrackedWarp'})

	print ('"'..newGW.Name..'" created"')	
	
end

--
-- Run Tracker
--
function win.On.btnDoTrack.Clicked(ev)
	
	if not newTracker then
		newTracker = composition:FindTool(itm.varTracker.Text)
	end
	
	if newTracker then
		print ('Running Tracking for "'..newTracker.Name..'"')
		composition.CurrentTime = 0
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
	
win:Show()
disp:RunLoop()
win:Hide()


