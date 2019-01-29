
--[[
Fusion Global Variable Viewer - v1 2018-12-07
by Andrew Hazelden
Email: <andrew@andrewhazelden.com>
Web: www.andrewhazelden.com
----------------------------------------------

# Overview #

This code snippet writes out the value of *all* Fusion internal global variables to disk by saving it to a PathMap file located at "Temp:/FusionGlobals.txt".

This script is compatible with Fusion 9.0.2+ and uses UI Manager for the GUI.

# Usage #

Step 1. Save your Fusion composite to disk.

Step 2. Open the "Fusion Global Variable Viewer.lua" document up in a text editor like notepad++ or BBEdit. Copy the full lua script contents into your clipboard and paste it into the Fusion Console window's single line text field. This will run the script with the same scope as your own code you would type into the Console.

Step 3. The script will save a file with all the active global variables to "Temp:/Fusion/FusionGlobals.txt". Then 10 seconds later that document will open up in a Fusion UI Manager based syntax highlighted text editor view.


# Linux Note #

If you run this script on Linux and it crashes Fusion the error is likey related to the Syntax Highlighting code.

Try disabling this line of code by adding two dashes -- as comment to the start of the line:

Lexer = 'fusion',}, 

--]]--

print('----------------------------------------------')
print('Fusion Global Variable Viewer - v1 2018-12-07')
print('by Andrew Hazelden')
print('Email: <andrew@andrewhazelden.com>')
print('Web: www.andrewhazelden.com')
print('----------------------------------------------')

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow({
	ID = 'EditWin',
	TargetID = 'EditWin',
	Geometry = {0, 0, 600, 600},
	WindowTitle = 'Fusion Global Variable Viewer',
	ui:VGroup{
		ID = "root",
		
		-- Add your GUI elements here:
		ui:HGroup{
		Weight = 1,
		ui:TextEdit{
			ID = 'TextEdit',
			TabStopWidth = 28,
			Font = ui:Font{
				Family = 'Droid Sans Mono', 
				StyleName = 'Regular', 
				PixelSize = 12, 
				MonoSpaced = true, 
				StyleStrategy = {
					ForceIntegerMetrics = true
				}, 
				ReadOnly = true,
			},
			LineWrapMode = 'NoWrap',
			AcceptRichText = false,

			-- Use the Fusion hybrid lexer module to add syntax highlighting
			Lexer = 'fusion',
			},
		},
		
		ui:HGroup{
			Weight = 0.1,
			ui:Button{ID = "Refesh", Text = "Refresh Document",},
		},
		
	},
})

itm = win:GetItems()

-- Add your GUI element based event functions here:

-- Track the Fusion save events
ui:AddNotify("Comp_Save", comp)
ui:AddNotify("Comp_SaveVersion", comp)
ui:AddNotify("Comp_SaveAs", comp)
ui:AddNotify("Comp_SaveCopyAs", comp)
 
-- The window was closed
function win.On.EditWin.Close(ev)
	disp:ExitLoop()
end

-- The "Refresh" button was pressed.
function win.On.Refesh.Clicked(ev)
	print('[Update] Refreshing the view.')
	RefeshDocument()
end

-- The Fusion "Save" command was used
function disp.On.Comp_Save(ev)
	print('[Update] Comp saved. Refreshing the view.')
	RefeshDocument()
end

-- The Fusion "Save Version" command was used
function disp.On.Comp_SaveVersion(ev)
	print('[Update] Comp saved as a new version. Refreshing the view.')
	RefeshDocument()
end

-- The Fusion "Save As" command was used
function disp.On.Comp_SaveAs(ev)
	print('[Update] Comp saved to a new file. Refreshing the view.')
	RefeshDocument()
end

-- The Fusion "Save Copy As" command was used
function disp.On.Comp_SaveCopyAs(ev)
	print('[Update] Comp saved as a copy to a new file. Refreshing the view.')
	RefeshDocument()
end

-- Load the current Fusion composite source contents into the viewer:
function RefeshDocument()
	print('Please be patient for about 10 seconds as this script runs. A 5 MB text file will be saved and opened.')
	
	-- The Fusion "Temp:/Fusion/" PathMap folder is created.
	local pathFolder = app:MapPath('Temp:/Fusion/')
	if bmd.direxists(pathFolder) == false then
		bmd.createdir(pathFolder)
		print('[Created Temp Folder] ' .. pathFolder)
	end
	
	-- File to save to disk
	globalsExportFile = app:MapPath(pathFolder .. 'FusionGlobals.txt')
	
	-- Write the Fusion internal global variables to disk
	print('[Saving file] ' .. tostring(globalsExportFile))
	bmd.writefile(globalsExportFile, dumptostring(getfenv()):gsub('\t', [[
	]]))
	
	-- Read in the active .txt as a file from disk then trim off the final null character from the file
	print('[Reading file]')
	rawDocument = io.open(globalsExportFile, 'r'):read('*all')
	--document = rawDocument:sub(1,-2)
	document = rawDocument:sub(1,-2):gsub([[\\n]], '\n')
	
	-- Update the TextEdit field contents
	itm.TextEdit.PlainText = document
	
	-- Update the window title caption with the filename
	-- itm.EditWin.WindowTitle = 'Fusion Global Variable Viewer: ' .. globalsExportFile
	
	-- Open up a desktop folder browsing window to this location
	print('[Show Temp Folder] ' .. pathFolder)
	bmd.openfileexternal("Open", pathFolder)
end


RefeshDocument()

win:Show()
bgcol = { R=0.125, G=0.125, B=0.125, A=1 }
itm.TextEdit.BackgroundColor = bgcol
itm.TextEdit:SetPaletteColor('All', 'Base', bgcol)

-- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
app:AddConfig('EditWin', {
	Target {
		ID = 'EditWin',
	},

	Hotkeys {
		Target = 'EditWin',
		Defaults = true,
		
		CONTROL_W = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
		CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
	},
})

disp:RunLoop()
win:Hide()

