------------------------------------------------------------------------------
-- Remote Monitor.eyeonscript -- Version 1.5
--
-- Utility script.
--
-- This script acts as a remote render monitor with Fusion 5.01
-- Updates: March 14 - fixed issue with setting timeout on connection. 
-- written by : sean konrad (sean@eyeonline.com)
-- updated : Mar. 31, 2015 by blazej floch
-- updated : Mar. 14, 2006
-- updated : January/February 2018 by Eric "SirEdric" Westphal <eric@siredric.de>
--			redone in large chunks for Fusion 9.x 
--			Thanks to Andrew Hazelden for his excellent examples on the new Fusion UI Manager
------------------------------------------------------------------------------


-- Because the lists are generated dynamically and display the slave / job info, what I've done is keep track of the 
-- number of slaves/ jobs and then use for loops with the iterating value converted to a string.

-- This gives definition to the numbers returned by the 'status attributes
-- for render jobs. This has been converted to a string variable from a numeric index.

-- To make this work properly, we needed a new function to check to make sure that the manager still existed as 
-- repeatedly connecting was doing, well, bad things. As such, this script won't function in 5.0. You probably
-- shouldn't use the release build anyway.

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 800,800
spacerWeight = 0.05
theUser = fusion:GetEnv("USERNAME")
dodebug = false

customGroups = {"all", "stream", "single", "power", "CPU", "GPU"}


function eprint(stuff)
	if dodebug == true then
		print("[Debug] ", stuff)
	end
end

function edump(stuff)
	if dodebug == true then
		print("[Debug Dump] ")
		dump(stuff)
	end
end

function jobSafetyCheck() -- to be implemented in job actions
	jl_new = nil
	jl_new = {}
	jl_new = GetTrueJobList(rm)
	edump(jl_new)
	cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
end

-- btn_browse = ui:Button {ID = "btn_browse", Text = "Browse", Weight = 0.2}
-- textFileBox = ui:Label{ ID = "textFileBox", Text = "c:\\program files\\fusion\\comps\\", Weight = 0.2}
-- btn_OK = ui:Button {ID = "btn_OK", Text = "OK", Weight = 0.2}
-- btn_Cancel = ui:Button {ID = "btn_Cancel", Text = "Cancel", Weight = 0.2}

-- Connect to the local fusion interface.
if not fusion then
	-- The second argument is the timeout. Otherwise it will try to connect forever.
	fusion = Fusion("localhost", 10)
end
-- Set the master variable which will be used to connect to the render manager in question.
-- If there's no instance of Fusion, set it to connect to localhost (which it won't be able to do). Then let the user specify.
if not fusion then 
	master = "localhost" 
else 
	fusion:SetTimeout(0)
	master = fusion:GetPrefs()["Global"]["Network"]["ServerName"] 
end



----------------------------------------------------------------------------------------------------------------------------------------------------
-- This section is for spawning the interface of both the main window and the popup windows..-------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------


win = disp:AddWindow({
	ID = 'MyWin',
	WindowTitle = 'Fusion 9 Remote Render Monitor v0.5',
	--Geometry = { 100, 100, width, height },
	Geometry = { 100, 100, 900, 700 },
	Spacing = 10,

	ui:VGroup {
		ID = 'root',
		Alignment = {
			AlignHCenter = true,
			AlignTop = true,
			},
		
		ui:HGroup {Weight = 0.01,
			ui:Label{ID = "jlLabel", Text = "[ JOB LIST ]", Alignment = {AlignHCenter = true, AlignVCenter = true,},},
		},
		ui:HGroup {Weight = 0.01,
			ui:Label{Text = "Due to the absence of a proper timer click refresh to update manually.", Alignment = {AlignHCenter = true, AlignVCenter = true,},},
		},
		ui:HGroup {--Weight = 0.5,
			ui:VGroup { Weight = 0.2, 
				ui:Button{ID = "btn_refresh", Text = "Refresh", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_refresh.png'}},
				ui:Button{ID = "btn_delete", Text = "Delete Job", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_delete.png'}},
				ui:Button{ID = "btn_addjob", Text = "Add Job", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_add.png'}},
				ui:Button{ID = "btn_moveUp", Text = "Job one Up", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_up.png'}},
				ui:Button{ID = "btn_moveDown", Text = "Job one Down", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_down.png'}},
				ui:Button{ID = "btn_moveTop", Text = "Job to Top", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_top.png'}},
				ui:Button{ID = "btn_moveBot", Text = "Job to Bottom", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_bottom.png'}},
				ui:Button{ID = "btn_openLocal", Text = "Open Comp", Weight = 0.2, Icon = ui:Icon{File = 'Scripts:/Utility/rm_open.png'}},
				ui:Label{Text = "Job's Groups:"},
				ui:LineEdit{ID = "textGroupsJob", Text = "---", Weight = 0.2},
				ui:Button{ID = "btn_GroupsJob", Text = "Mod Job Groups", Weight = 0.2},
				ui:Button{ID = "btn_GroupsAll", Text = "Set Group to 'all'", Weight = 0.2},
				ui:ComboBox{ID = 'grpCombo', Text = 'Combo Menu',},
							},
			ui:VGroup {Weight = spacerWeight}, -- just a spacer!
			ui:VGroup {
				ui:Tree{ID = 'JobList', SortingEnabled=true, Events = { ItemDoubleClicked=true, ItemClicked=true }, }
			}, 
		},
		ui:HGroup {Weight = 0.01,
			ui:Label{Text = "[ SLAVE LIST ]", Alignment = {AlignHCenter = true, AlignVCenter = true,},},
			},
		ui:HGroup {
			ui:VGroup {Weight = 0.2, 
				ui:Button{ID = "btn_addSlave", Text = "Add Slave", Weight = 0.2},
				ui:Button{ID = "btn_remSlave", Text = "Remove Slave", Weight = 0.2},
				ui:Button{ID = "btn_scan", Text = "Scan for Slaves", Weight = 0.2},
				ui:Label{Text = "Slave's Groups:"},
				ui:LineEdit{ ID = "textGroupsSlave", Text = "---", Weight = 0.2},
				ui:Button{ID = "btn_GroupsSlave", Text = "Mod Slave Groups", Weight = 0.2},
				ui:Button{ID = "btn_GroupsSlaveAll", Text = "Assign Group 'all'", Weight = 0.2},
			},
			ui:VGroup {Weight = spacerWeight}, -- just a spacer!

			ui:VGroup {
				ui:Tree{ID = 'SlaveList', SortingEnabled=true, Events = { ItemDoubleClicked=true, ItemClicked=true }, }
			},
		},

		ui:HGroup {Weight = 0.01,
		ui:VGroup { 
			ui:HGroup{
				-- Set up the connection button and its associated text box. 
				ui:Button{ID = "btn_Connect", Text = "Connect...", Weight = 0.2},
					ui:VGroup {Weight = spacerWeight}, -- just a spacer!
				ui:LineEdit{ ID = "textConnect", Text = "127.0.0.1"},
				},
			},
		},
		
		ui:HGroup{Weight = 0.01,
			ID = "buttons",
			--ui:Button{ID = 'OK', Text = 'Okay'},
			ui:CheckBox{ID = 'doVerbose', Text = 'Verbose Console logging', Checked = false},
			ui:Label{ ID = "sysmsg", Text = "---", Weight = 1},
			ui:Label{ ID = "slavemsg", Text = "---", Weight = 1},
			ui:Button{ID = 'cncl', Text = 'Close Window', Weight = 0.01},
		},
	},
 })
 
 winbrowse = disp:AddWindow({
 ID = 'FileBrowser',
 WindowTitle = 'Add comp file to Queue',
 Geometry = {100, 100, 600, 100},
 Spacing = 10,
 Margin = 10,
 
		ui:VGroup{ ID = 'root', Weight = 1,
		ui:HGroup{ Weight = 0.01,
			ui:Label{
				ID='FileTxt',
				Text = 'Select a composition',
				Weight = 0.2,
			},
			ui:Button{
					 ID = 'FileButton',
					 Text = 'Browse',
					 Weight = 0.01,
				},
  },
		ui:HGroup{ Weight = 0.01, --AlignCenter,
				
				ui:Button{
					ID = 'but_ok',
					Text = 'Add to queue',
					Weight = 0.01,
				},
				ui:Button{
					ID = 'but_cancel',
					Text = 'Cancel',
					Weight = 0.01,
				},
		},
	},
 })

win3 = disp:AddWindow({
	ID = 'MyWin3',
	WindowTitle = 'Add Render Slave by Name or IP',
	--Geometry = { 100, 100, width, height },
	Geometry = { 100, 100, 600, 75 },
	Spacing = 10,
	Margin = 10,
			
			ui:VGroup {--Weight = 1,
			ID = "vboxSlave",
				ui:HGroup{Weight = 0.01,
					ui:Label{Text = "HostID or IP:", Weight = 0.01},
					--textSlave
					ui:LineEdit{ ID = "textSlave", Text = "Enter Host or ID here." }
				},
				ui:HGroup {Weight = 0.01,
					ui:Label{Text = " ", Weight = 0.2}, -- fake spacer!
					--btn_OKSlave,
					ui:Button {ID = "btn_OKSlave", Text = "OK", Weight = 0.01},
					--btn_CancelSlave,
					ui:Button {ID = "btn_CancelSlave", Text = "Cancel", Weight = 0.01},
				},
			},
 })

 itm = win:GetItems()
 itmSlv = win3:GetItems()

----------------------------------------------------------------------
-- now let's fill the tree controls with some headers and stuff --
----------------------------------------------------------------------

 -- SlaveList Header
	hdr = itm.SlaveList:NewItem()
	hdr.Text[0] = 'Name'
	hdr.Text[1] = 'IP'
	hdr.Text[2] = 'Fusion Version'
	hdr.Text[3] = 'Status'
	hdr.Text[4] = 'Groups'
	hdr.Text[5] = 'idx'
	--itm.Tree:SetHeaderItem(hdr)
	itm.SlaveList:SetHeaderItem(hdr)
 
 -- Resize the Columns
	itm.SlaveList.ColumnWidth[0] = 175
	itm.SlaveList.ColumnWidth[1] = 125
	itm.SlaveList.ColumnWidth[2] = 100
	itm.SlaveList.ColumnWidth[3] = 100
	itm.SlaveList.ColumnWidth[4] = 150
	itm.SlaveList.ColumnWidth[5] = 25	
	
	
-- JobList Header
	hdr = itm.JobList:NewItem()
	hdr.Text[0] = 'Job Name'
	hdr.Text[1] = 'Groups'
	hdr.Text[2] = 'Frames Rendered'
	hdr.Text[3] = 'Status'
	hdr.Text[4] = '-' -- not sure if this is ever needed....
	hdr.Text[5] = 'Priority' -- was 'idx'. This defines the Position of the job in the queue!
	--itm.Tree:SetHeaderItem(hdr)
	itm.JobList:SetHeaderItem(hdr)
 
 -- Resize the Columns
	itm.JobList.ColumnWidth[0] = 200
	itm.JobList.ColumnWidth[1] = 150
	itm.JobList.ColumnWidth[2] = 150
	itm.JobList.ColumnWidth[3] = 120
	itm.JobList.ColumnWidth[4] = 10
	itm.JobList.ColumnWidth[5] = 50

 -- fill group combo
 for _, grp in pairs (customGroups) do
	itm.grpCombo:AddItem(grp)
end
 -----------------------
 -- functions  for Window3 --
 -----------------------
 function win3.On.MyWin3.Close(ev) -- The window was closed
	win:Hide()
	disp:ExitLoop()
end

function win3.On.btn_CancelSlave.Clicked(ev)
	--dump(win)
	win3:Hide()
	--	disp:ExitLoop()
end

function win3.On.btn_OKSlave.Clicked(ev)
	--dump(win)
	win3:Hide()
	--	disp:ExitLoop()
end


--------------------------
-- functions for MainWindow --
--------------------------
function win.On.MyWin.Close(ev) -- The window was closed
	win:Hide()
	disp:ExitLoop()
end


 
function win.On.cncl.Clicked(ev) -- cancel was clicked
	win:Hide()
	disp:ExitLoop()
end

function win.On.grpCombo.CurrentIndexChanged(ev)
	selGroup = customGroups[itm.grpCombo.CurrentIndex + 1]
	eprint(selGroup)
	
	if selectedJob and tonumber(selectedJob.Text[5]) ~=0 then
		if connectCheck() then
			jl_new = nil
			jl_new = {}
			jl_new = GetTrueJobList(rm)
			cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
			if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
				rm:Log("REMOTE at " .. theUser .. " modified Groups of job : "..jl_new[cur_Sel]:GetAttrs().RJOBS_Name)
				jl_new[cur_Sel]:SetAttrs({RJOBS_Groups = selGroup})
				wait(1)
				refreshMonitor()
			else
				clear_j()
				itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
			end
		end
	end
	
end

function win.On.JobList.ItemClicked(ev) -- some item in the joblist was selected
	selectedJob = ev.item
    eprint (selectedJob.Text[0] .. " - " .. selectedJob.Text[5])

	-- stuff from former j.Clicked()
	if connectCheck() then		
		if tonumber(selectedJob.Text[5]) ~= 0 then
			-- if it's connected, then change the text box to equal the RJOBS_Groups attribute
			bla = tonumber(selectedJob.Text[5])
			eprint("Job Clicked: " .. jl[bla])
			itm.textGroupsJob.Text = jl[tonumber(selectedJob.Text[5])]:GetAttrs().RJOBS_Groups
		end
	end
	
end

function win.On.SlaveList.ItemClicked(ev) -- some item in the slavelist was selected
	selectedSlave = ev.item
    eprint (selectedSlave.Text[0] .. " - " .. selectedSlave.Text[5])
	
	--stuff from former s.Clicked()
	if connectCheck() then		
		if itm.slavemsg.Text then
			itm.textGroupsSlave.Text = sl[tonumber(selectedSlave.Text[5])]:GetAttrs().RSLVS_Groups
		end
	end

end

function win.On.doVerbose.Clicked(ev)
	dodebug = itm.doVerbose.Checked
	eprint("verbose = " , itm.doVerbose.Checked)
end


 -- Functions for FileBrowser Window
 itm_browse = winbrowse:GetItems()
 
function winbrowse.On.MyWin.Close(ev) -- The filebrowse window was closed
	--disp:ExitLoop() --needed for every window?
	winbrowse:Hide()
end
 
-- The Open File button was clicked
function winbrowse.On.FileButton.Clicked(ev)
	eprint('Open File Button Clicked')
	selectedPath = tostring(comp:MapPath(fu:RequestFile('Comps:')))
 
	eprint('[File] ', selectedPath)
	itm_browse.FileTxt.Text = selectedPath
	return selectedPath
 end
 
 function winbrowse.On.but_ok.Clicked(ev)
	--disp:ExitLoop()
	winbrowse:Hide()
	-- Check to see if the file exists.
	if fileexists(selectedPath) == true then
		-- Add the job...
		rm:AddJob(selectedPath)
		-- Print in the log...
		rm:Log("REMOTE at " .. theUser .. " added job : ".. selectedPath)
	end
	-- Refresh.
	refreshMonitor()
	return selectedPath

 end

function winbrowse.On.but_cancel.Clicked(ev)
	--disp:ExitLoop()
	winbrowse:Hide()
end


function getfilename(path)
	for i = string.len(path), 1, -1 do
		teststring = string.sub(path, i, i)
		if teststring == "\\" or teststring == "/" then
			return string.sub(path, i+1)
		end
	end
end

-- This will format the slave's attributes so that it can be properly displayed later on in the interface.
-- Since this has been converted to the iup interface, the formatting hasn't been quite as perfect
-- as the console dump version of this script.

function fmtSlave(slave, idx)
	
	-- Get the slave's attributes.
	slv = slave:GetAttrs()
	
	-- If it has priority classes?
	if slv.RSLVS_PriorityClasses == nil then classes = "N/A" else classes = slv.RSLVS_PriorityClasses end
	
	-- Get the slave's status.
	local status = slv.RSLVS_Status
	-- The string.format function is being used here to determine spacing for the 
	-- name, IP, version, status, and classes if they exist. Return the string.
	itRow = itm.SlaveList:NewItem();
		-- String.format is used to create a leading zero padded row number like 'Row A01' or 'Row B01'.
	--itRow.Text[0] = string.format("%-30.30s", slv.RSLVS_Name)
	itRow.Text[0] = slv.RSLVS_Name
	itRow.Text[1] = slv.RSLVS_IP
	itRow.Text[2] = slv.RSLVS_Version
	itRow.Text[3] = tostring(status)
	--itRow.Text[4] = string.format("%-10.10s", classes) -- dropped this for groups
	itRow.Text[4] = tostring(slv.RSLVS_Groups)
	itRow.Text[5] = tostring(idx)

	itm.SlaveList:AddTopLevelItem(itRow)

end

-- This will format the job's attributes so that it can be displayed in the iup list box.
-- This is having the same problem as the above function since its conversion to the iup format.

function fmtJob(job, idx)
	a = job:GetAttrs()
	eprint(a)
	
	-- Get the total number of frames by adding the Unrendered, Rendered, and Rendering frames.
	total = a.RJOBN_UnrenderedFrames + a.RJOBN_RenderedFrames + a.RJOBN_RenderingFrames
	eprint(total)
	--Also get the total number of rendered frames.
	done = a.RJOBN_RenderedFrames

	if a.RJOBS_PriorityClass == nil then
		classes = nil
	else
		classes = a.RJOBS_PriorityClass
	end
 
	if a.RJOBS_Type == "Comp" then
		-- Here we use string.format to define the spacing between job names.
		-- Incidentally, the only reason this works is because we're using a fixed width font
		-- in the list box (Courier). 
		
		-- this needs to be modified to fill the ui:tree!------------------------------------------------------------------------
		itRow = itm.JobList:NewItem();
		-- String.format is used to create a leading zero padded row number like 'Row A01' or 'Row B01'.
		--itRow.Text[0] = string.format("%-35.35s", eyeon.parseFilename(a.RJOBS_Name).FullName);
		itRow.Text[0] = bmd.parseFilename(a.RJOBS_Name).FullName
		--itRow.Text[1] = string.format("%-16.16s", a.RJOBS_QueuedBy); -- replaced this with groups!
		itRow.Text[1] = a.RJOBS_Groups
		itRow.Text[2] = done.."/"..total
		itRow.Text[3] = a.RJOBS_Status
		if classes then
			itRow.Text[4] = classes
		end
		itRow.Text[5] = tostring(idx)
		itm.JobList:AddTopLevelItem(itRow)

-- do we need this section???		
--[[
		local strAssembly = string.format("%-35.35s", eyeon.parseFilename(a.RJOBS_Name).FullName).." "..
		string.format("%-16.16s", a.RJOBS_QueuedBy).." "..
		string.format("%-15.15s", done.."/"..total).." "..
		string.format("%-15.15s", a.RJOBS_Status).." "
		if classes then
			strAssembly=strAssembly..string.format("%-10.10s", classes)
		end
		return strAssembly
--]]--
	end
end

-- This function was added in to check if the host server is still actually connected.
-- If it isn't, error out.

function connectCheck()
	print("connect Check")
	if masterConnect then 
		print("Master connect Check")
		if masterConnect:IsAppConnected() == true then 
			print("[connected]")
			itm.jlLabel.Text = "[ JOB LIST ] on "
			return true
		end
	end
	errorConnect()
	return nil
end

-- Error if the host is no longer connected.

function errorConnect()
	clear_j()
	clear_s()
	itm.sysmsg.Text = "Could not connect to ".. master
end

-- The GetJobList() function can returns jobs that are in the process of being deleted
-- from the queue. Unfortunately this sometimes takes longer than one would anticipate. As such,
-- this function skips over jobs that are being removed (determined by the RJOBB_IsRemoving attribute)

function GetTrueJobList(renderMaster)
	jobList = {}
	jobListTemp = {}
	jobListTemp = renderMaster:GetJobList()
	for i, v in pairs(jobListTemp) do
		attrs = v:GetAttrs()
		if attrs.RJOBB_IsRemoving == false then
			-- only add to the slave list if it's not being removed.
			table.insert(jobList, v)
		end
	end
	
	-- return the slaveList variable.
	return jobList
end

-- The GetSlaveList() function occasionally returns slaves that are in the process of being deleted
-- from the queue. Unfortunately this sometimes takes longer than one would anticipate. As such,
-- this function skips over slaves that are being removed (determined by the RSLVB_IsRemoving attribute)

function GetTrueSlaveList(renderMaster)
	slaveList = {}
	slaveListTemp = {}
	slaveListTemp = renderMaster:GetSlaveList()
	for i, v in pairs(slaveListTemp) do
		attrs = v:GetAttrs()
		if attrs.RSLVB_IsRemoving == false then
			
			-- only add to the slave list if it's not being removed.
			table.insert(slaveList, v)
		end
	end
	
	-- return the slaveList variable.
	return slaveList
end

-- This will first clear and then refill both of the list boxes.
function fillList()
	clear_j()
	clear_s()
	fill_j()
	fill_s()
end

-- Clears the list box named "J" 
function clear_j()
	itm.JobList:Clear()
	-- If there's an error message in the list NOT part of the list box, clear it.
	 if itm.sysmsg.Text then
		itm.sysmsg.Text = "joblist up to date"
	 end
end

function fill_j()

	-- Fill the job list box.
	-- Check the connection.
	if connectCheck() then
		-- Get the job list to fill the list with...
		jl = nil
		jl = {}
		jl = GetTrueJobList(rm)
		eprint("[JobList Retrieve]")
		edump(jl)
		for i, v in pairs(jl) do
			--j[tostring(i)]=fmtJob(v)
			fmtJob(v, i)
			edump(v)
		end
		itm.JobList:SortByColumn(5, "AscendingOrder")
	end
end

function fill_s()
	if connectCheck() then
		-- Get the slave list to fill the list with...
		sl = nil
		sl = {}
		sl = GetTrueSlaveList(rm)
		for i, v in pairs(sl) do
			--s[tostring(i)]=fmtSlave(v)
			fmtSlave(v, i)
		end
	end
end


function clear_s()
	itm.SlaveList:Clear()
end

-- This is the primary function used to connect to the master. It's also used to create the list boxes if they haven't been created yet.



function connectMaster()

	-- a boolean is defined to keep track of whether or not the list boxes have been created yet.
	if listsCreated then
	
		-- if they've already been created, they obviously want to change which master they're connecting to.
		master = itm.textConnect.Text
		eprint(master)
		
		-- connect to an instance of fusion -- defined by the 'master' variable. 
		-- set the timeout to 5, and make sure we connect to a Render manager first. 
		-- if that fails, connect to the main instance of Fusion.
		
		-- we specify RenderManager, because there's a chance that it might connect to another 
		-- instance of Fusion first. depending on which was opened first.
		masterConnect = Fusion(master, 5.0, nil, "RenderManager") 
		if masterConnect == nil then
			masterConnect = Fusion(master, 5.0) 
		end
		
		-- if it's connected display the lists.
		if connectCheck() == true then
			masterConnect:SetTimeout(0)
			-- also, define the rm variable.
			rm = masterConnect.RenderManager
			refreshMonitor()
		end
	else
	
		-- set the listsCreated boolean to true.
		listsCreated = true

		-- Connect
		masterConnect = Fusion(master, 5.0, nil, "RenderManager") 
		if masterConnect == nil then
			masterConnect = Fusion(master, 5.0) 
		end
		if masterConnect then
			masterConnect:SetTimeout(0)
			rm = masterConnect.RenderManager
			fillList()
		else
			errorConnect()
		end
	end
end


-- Connect!! why not?
connectMaster()

		j = ui:Tree{ID = 'JobList', SortingEnabled=true, Events = { ItemDoubleClicked=true, ItemClicked=true }, }
		s = ui:Tree{ID = 'SlaveList', SortingEnabled=true, Events = { ItemDoubleClicked=true, ItemClicked=true }, }
		




----------------------------------------------------------------------------------------------------------------------------------------------------
-- This section is for functions related to file browsing for a .comp file to add to the manager.---------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

function addJob()

	winbrowse:Show()

end

function addJob_fileDLG()
	-- Creates a file dialog and sets its type, title, filter and filter info
	filedlg = iup.filedlg{dialogtype = "OPEN", Text = "File Open", 
 filter = "*.comp", filterinfo = "Fusion .comp File",
 directory="c:\\program files\\fusion\\comp\\"} 

	-- Shows file dialog in the center of the screen
	filedlg:popup (iup.ANYWHERE, iup.ANYWHERE)
	-- Gets file dialog status
	status = filedlg.status
	-- if it found the file...

	
	return filedlg.value
	
end
----------------------------------------------------------------------------------------------------------------------------------------------------
-- This section is for functions related to file browsing for a .comp file to add to the manager.---------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

function refreshMonitor()
	
	-- The usual step for anything related to the manipulation of the queue is to check if it's conected...
	
	if connectCheck() then
		
		-- if it is, clear the boxes and refill them
		clear_j()
		fill_j()
		
		-- and the same for the slave boxes...
		clear_s()
		fill_s()
		
		-- clear the text boxes as nothing will be highlighted anymore.
		itm.textGroupsJob.Text = ""
		itm.textGroupsSlave.Text = ""
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------
------------- This area of the code exists primarily as an area for button press related functions -------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------


function win.On.btn_refresh.Clicked(ev)
	-- Refill the list boxes. The function refreshMonitor will check to make sre that it's still connected to Fusion
	-- for us, so no need to call it now.
	refreshMonitor()
 end


-- This is the action for the button that deletes the selected job from the queue.
function win.On.btn_delete.Clicked(ev)
	-- if the list even has an entry in it..
	if selectedJob then
		edump(selectedJob)
		-- Get the currently selected entry -- convert it to a number value so that it can actually be used 
		-- when we're iterating through tables..
		cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
		--selectedJob.Text[0]
		-- if something is selected...
		if cur_Sel ~=0 then
		--if selectedJob then
		
			-- if it's connected ..
			if connectCheck() then 
				
				-- Get the job list to see if it still matches the old job list (in case the job list somehow got altered -- job already deleted, etc.).
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				edump(jl_new)
				
				
				-- Compare the old list to the new..
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					
					-- Display a message in the monitor with using the Log() function..
					--rm:Log("REMOTE at " .. theUser .. " job removed "..jl[cur_Sel]:GetAttrs().RJOBS_Name)
					rm:Log("REMOTE at " .. theUser .. " job removed "..selectedJob.Text[0])
					
					-- Remove the job
					--rm:RemoveJob(selectedJob)
					rm:RemoveJob(jl_new[cur_Sel])
					
					-- Give it a second to delete.
					wait(1)
					--ev.item.Text[0]
					-- Refresh.
					refreshMonitor()
				else
				
					-- If the entries no longer match, display an error.
					clear_j()
					--itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
					itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
				end
			end
		end
	end
--	return iup.DEFAULT
end


-- This is the button action for the removing of slaves..

function win.On.btn_remSlave.Clicked(ev)
	-- Do a similar set of checks to what we did above.
	if itm.slavemsg.Text then
		cur_Sel = tonumber(selectedSlave.Text[5]) --this is the (pseudo automatic) index of the slave
		-- cur_Sel = tonumber(selectedSlave.Text[5]) --OLD stuff
		if cur_Sel ~= 0 then
			if connectCheck() then
				sl_new = nil
				sl_new = {}
				
				-- The slave list that is returned by the function GetSlaveList() function
				-- sometimes has slaves that are being deleted, but are taking a second to disconnect
				-- therefore they don't show up in the slave list on the actual monitor. We shouldn't display them either.
				-- Hence GetTrueSlaveList()
				sl_new = GetTrueSlaveList(rm)
				if tostring(sl[cur_Sel]) == tostring(sl_new[cur_Sel]) then
					rm:Log("REMOTE at " .. theUser .. " slave removed "..sl[cur_Sel]:GetAttrs().RSLVS_Name)
					rm:RemoveSlave(sl_new[cur_Sel]:GetAttrs().RSLVS_IP)
					
					wait(1)
					refreshMonitor()
				else
					clear_s()
					itm.slavemsg.Text = "Slave list modified since last update -- please refresh and try again."
				end
			end
		end
	end
	--return iup.DEFAULT
end


-- This button scans for slaves.
function win.On.btn_scan.Clicked(ev)
	-- Check the connection.
	if connectCheck() then
	
		-- Scan for the slaves. Render manager related function.
		rm:ScanForSlaves()
		
		-- Add a note to the log.
		rm:Log("REMOTE at " .. theUser .. " scanned for slaves.")
		wait(1)
		
		-- Refresh.
		refreshMonitor()
	end
	--return iup.DEFAULT
end

-- The button that will move the job up in priority...
function win.On.btn_moveUp.Clicked(ev)

	-- Check the job list in a similar fashion to above..
--	if itm.sysmsg.Text then --no idea what this is good for?
		if selectedJob and tonumber(selectedJob.Text[5]) ~= 0 then
			eprint("[Move Up] " .. tonumber(selectedJob.Text[5]))
			if connectCheck() then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				edump(jl_new)
				
				-- cur_Sel = tonumber(selectedJob.Text[5])
				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					
					-- Print something in the log..
					rm:Log("REMOTE at " .. theUser .. " modified job priority "..jl[cur_Sel]:GetAttrs().RJOBS_Name.. " up.")
					
					-- Move the job up -- -1 moves it up one entry.
					rm:MoveJob(jl[cur_Sel] , -1)
					
					wait(1)
					refreshMonitor()
				else
					clear_j()
					itm.sysmsg.Text = "Queue modified since last update."
				end
			end
		end
--	end
	--return iup.DEFAULT
end

function win.On.btn_moveTop.Clicked(ev)
		if selectedJob and tonumber(selectedJob.Text[5]) ~= 0 then
			eprint("[Move Top] " .. tonumber(selectedJob.Text[5]))
			if connectCheck() then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				edump(jl_new)

				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					-- Print something in the log..
					rm:Log("REMOTE at " .. theUser .. " made Job "..jl[cur_Sel]:GetAttrs().RJOBS_Name.. " into top priority.")
					-- Move the job up -- -1 moves it up one entry.
					rm:MoveJob(jl[cur_Sel] , -cur_Sel)
					wait(1)
					refreshMonitor()
				else
					clear_j()
					itm.sysmsg.Text = "Queue modified since last update."
				end
			end
		end
end

function win.On.btn_moveBot.Clicked(ev)
		if selectedJob and tonumber(selectedJob.Text[5]) ~= 0 then
			eprint("[Move Top] " .. tonumber(selectedJob.Text[5]))
			if connectCheck() then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				edump(jl_new)

				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				numJobs = #jl_new
				
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					-- Print something in the log..
					rm:Log("REMOTE at " .. theUser .. " made Job "..jl[cur_Sel]:GetAttrs().RJOBS_Name.. " into top priority.")
					-- Move the job up -- -1 moves it up one entry.
					rm:MoveJob(jl[cur_Sel] , numJobs - cur_Sel)
					wait(1)
					refreshMonitor()
				else
					clear_j()
					itm.sysmsg.Text = "Queue modified since last update."
				end
			end
		end
end

-- See above function.
function win.On.btn_moveDown.Clicked(ev)
--	if itm.sysmsg.Text then --no idea what this is good for?
		if connectCheck() then
				if selectedJob and tonumber(selectedJob.Text[5]) ~= 0 then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				edump(jl_new)
				
				--cur_Sel = tonumber(selectedJob.Text[5])
				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				if jl[cur_Sel] == jl_new[cur_Sel] then
					rm:Log("REMOTE at " .. theUser .. " move job priority "..jl[cur_Sel]:GetAttrs().RJOBS_Name.. " down.")
					
					-- A positive integer being passed into the second argument will move the priority down one.
					rm:MoveJob(jl[cur_Sel] , 1)
					wait(1)
					refreshMonitor()
				else
					clear_j()
					itm.sysmsg.Text = "Queue modified since last update."
				end
			end
		end
--	end
	--return iup.DEFAULT
end

-- This button (and associated text box) will modify the groups of the selected slave.
function win.On.btn_GroupsSlave.Clicked(ev)
	
	-- Yadda.
	--if itm.slavemsg.Text then
	--if selectedJob then
		if tonumber(selectedSlave.Text[5]) ~= 0 then
			sl_new = nil
			sl_new = {}
			
			if connectCheck() then
				sl_new = GetTrueSlaveList(rm)
				-- cur_Sel = tonumber(selectedSlave.Text[5]) -- old stuff
				cur_Sel = tonumber(selectedSlave.Text[5]) --this is the (pseudo automatic) index of the job
				if tostring(sl[cur_Sel]) == tostring(sl_new[cur_Sel]) then
				
					-- Add something to the log.
					rm:Log("REMOTE at " .. theUser .. " modified Groups of slave : "..sl_new[cur_Sel]:GetAttrs().RSLVS_Name)
					
					-- Set RSLVS_Groups attribute equal to that of the text box. Hopefully the user doesn't put any invalid slave
					-- groups into the text box.
					sl_new[cur_Sel]:SetAttrs({RSLVS_Groups = itm.textGroupsSlave.Text})
					
					wait(1)
					refreshMonitor()
				else
					-- Display an error.
					clear_s()
					itm.slavemsg.Text = "Slave list modified since last update -- please refresh and try again."
				end
			end
		end
	--end
	--return iup.DEFAULT
end

function win.On.btn_GroupsSlaveAll.Clicked(ev)
	
	-- Yadda.
	--if itm.slavemsg.Text then
	--if selectedJob then
		if tonumber(selectedSlave.Text[5]) ~= 0 then
			sl_new = nil
			sl_new = {}
			
			if connectCheck() then
				sl_new = GetTrueSlaveList(rm)
				-- cur_Sel = tonumber(selectedSlave.Text[5]) -- old stuff
				cur_Sel = tonumber(selectedSlave.Text[5]) --this is the (pseudo automatic) index of the job
				if tostring(sl[cur_Sel]) == tostring(sl_new[cur_Sel]) then
				
					-- Add something to the log.
					rm:Log("REMOTE at " .. theUser .. " modified Groups of slave : "..sl_new[cur_Sel]:GetAttrs().RSLVS_Name)
					
					-- Set RSLVS_Groups attribute equal to that of the text box. Hopefully the user doesn't put any invalid slave
					-- groups into the text box.
					sl_new[cur_Sel]:SetAttrs({RSLVS_Groups = "all"})
					
					wait(1)
					refreshMonitor()
				else
					-- Display an error.
					clear_s()
					itm.slavemsg.Text = "Slave list modified since last update -- please refresh and try again."
				end
			end
		end
	--end
	--return iup.DEFAULT
end

-- Holla back (see above).
function win.On.btn_GroupsJob.Clicked(ev)
--	if itm.sysmsg.Text then --no idea what this is good for?
		if tonumber(selectedJob.Text[5]) ~=0 then
			if connectCheck() then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				-- cur_Sel = tonumber(selectedJob.Text[5]) -- old stuff
				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					rm:Log("REMOTE at " .. theUser .. " modified Groups of job : "..jl_new[cur_Sel]:GetAttrs().RJOBS_Name)
					jl_new[cur_Sel]:SetAttrs({RJOBS_Groups = itm.textGroupsJob.Text})
					
					wait(1)
					refreshMonitor()
				else
					clear_j()
					--itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
					itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
				end
			end
		end
--	end
	--return iup.DEFAULT
end

function win.On.btn_GroupsAll.Clicked(ev)
--	if itm.sysmsg.Text then --no idea what this is good for?
		if selectedJob and tonumber(selectedJob.Text[5]) ~=0 then
			if connectCheck() then
				jl_new = nil
				jl_new = {}
				jl_new = GetTrueJobList(rm)
				-- cur_Sel = tonumber(selectedJob.Text[5]) -- old stuff
				cur_Sel = tonumber(selectedJob.Text[5]) --this is the (pseudo automatic) index of the job
				if tostring(jl[cur_Sel]) == tostring(jl_new[cur_Sel]) then
					rm:Log("REMOTE at " .. theUser .. " modified Groups of job : "..jl_new[cur_Sel]:GetAttrs().RJOBS_Name)
					jl_new[cur_Sel]:SetAttrs({RJOBS_Groups = "all"})
					
					wait(1)
					refreshMonitor()
				else
					clear_j()
					--itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
					itm.sysmsg.Text = "Queue manipulated since last update -- please refresh and try again."
				end
			end
		end
--	end
end


----------------------------------------------------------------------------------------------------------------------------------------------------
------------- This area of the code exists primarily as an area for list click related functions ---------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------------------------------------
--------------- Functions related to the AddJob portion of the interface. --------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

-- This is the function that will run when the add job button is pressed. It will
-- spawn an interface that will spawn a file browsing window when called upon.

function win.On.btn_addjob.Clicked(ev)
	eprint("AddJob 1")
	
	-- Define the browse button action, which will spawn the file browsing window.
	function win.On.btn_browse.Clicked(ev)
	eprint("AddJob 2")
	
		-- Set the fileLoc variable using the addjob_fileDLG() function.
		fileLoc = selectedPath
		
		-- Set the text box equal to the value returned by fileLoc. If fileLoc is nil, then it won't set the text
		-- box's value.
		if fileLoc then
			--textFileBox.value = fileLoc
			itm.textFileBox.Text = fileLoc
		end
	end
	
	-- Use the addjob function..
	addJob()
	
	-- show the dialog at the center of the screen.
	--dlg_filebrowse:showxy(iup.CENTER, iup.CENTER)
	
	-- run this dialog's main loop.
	--iup.MainLoop{}
end

-- The action for the OK button of the file browse dialog..
function win.On.btn_OK.Clicked(ev)
	
	-- Check to see if the file exists.
	if fileexists(itm.textFileBox.Text) == true then
		
		-- Add the job...
		rm:AddJob(itm.textFileBox.Text)
		
		-- Print in the log...
		rm:Log("REMOTE at " .. theUser .. " added job : ".. itm.textFileBox.Text)
	end
	
	-- Reset the text box.
	itm.textFileBox.Text = ""
	

	-- Refresh.
	refreshMonitor()
end

function win.On.btn_Cancel.Clicked(ev)
	
	-- Clear the text box
	itm.textFileBox.Text = ""
	
	-- Hide the interface.
	--iup.Hide(dlg_filebrowse)
	
	-- Refresh for good measure.
	refreshMonitor()
end

----------------------------------------------------------------------------------------------------------------------------------------------------
--------------- Functions related to the AddSlave portion of the interface. ------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
function addSlave()
	-- We need to show the dialog to add the slave -- we've already defined the elements for it above.
	win3:Show()
end


-- The action for the btn_addSlave button..
function win.On.btn_addSlave.Clicked(ev)
	-- Calls the already declared "addSlave() function 
	addSlave()

end

-- Action for the OK button..
function win.On.btn_OKSlave.Clicked(ev)
	if connectCheck() then
	-- Check the connection, as per usual.
	-- Add the slave.
		rm:AddSlave(textSlave.value)
		
		-- We don't need to do any special to check to see if the slave exists or not
		-- at this point, becuase Fusion network rendering is generally smart enough to not add nonexistant slaves. 
	
		-- or it might add them, but it won't do anything with them.
		rm:Log("REMOTE at " .. theUser .. " added slave : "..textSlave.value)
	end
	
	textSlave.value = ""

	-- Check the connection! Everybody! 
	if connectCheck() then
		-- Refresh the monitor.
		refreshMonitor()
	end
end


function win.On.btn_Connect.Clicked(ev)
	connectMaster()
end



----------------------------------------------------------------------------------------------------------------------------------------------------
--------------- Automatic Refresh. -----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

-- We need a new timer here!

-- One of the nice features of IUP is the ability to create a timer
-- that will call an action every X units of time (milliseconds).


-- timer = iup.timer{time=30000.0, run="YES"}

 -- function timer:action_cb()
	-- if connectCheck() then
		-- refreshMonitor()
		-- return iup.DEFAULT
	-- else
		-- connectMaster()
	-- end
 -- end 
------------------------------------------

-- Bring up the dialogue

win:Show()
disp:RunLoop()

 
